#####
##### Plot spectral features for CAR-T SpotLite recordings
#####

using AWSS3
using BeaconPlots
using CairoMakie
using DataFrames
using Dates
using FilePathsBase
using Legolas
using Makie
using TimeSpans
using UUIDs

CMAP = Makie.wong_colors()

include("utils.jl")

function raincloud_power_plot(band_df, col)
    fig = Figure(; resolution=(1000, 600))
    ax = Axis(fig[1,1])
    sort!(band_df, [:subject, :date])
    subj_df = combine(groupby(band_df, [:subject, :color]), first)
    recording_power = combine(groupby(band_df,
                                      [:recording, :date_label, :color, :subject]),
                              col => (x -> [x]) => col)
    BeaconPlots.rainclouds!(ax, recording_power.date_label,
                            recording_power[!,col], palette=recording_power.color,
                            clouds=nothing, boxplot_width=0.4, boxplot_nudge=-0.2,
                            side_scatter_nudge=0, jitter_width=0.1,
                            show_outliers=false)
    ax.xticklabelrotation = pi / 4
    plot_colors = [PolyElement(color = CMAP[1]), PolyElement(color = CMAP[2]),
                   PolyElement(color = CMAP[3])]
    plot_colors = map(x -> PolyElement(color = x), subj_df.color)
    subject_ids = map(x -> string("Subject ", x), subj_df.subject)
    Legend(fig[2, 1], plot_colors, subject_ids; orientation=:horizontal,
           tellheight=true, tellwidth=false)
    return fig, ax
end

function main()
    power_df = read_dataframe(joinpath(SAVE_PATH, "cart.power.arrow");
                              validate=false)
    signals = read_dataframe(joinpath(SAVE_PATH, "cart.signals.arrow");
                             validate=false)
    # required for raincloud plot
    transform!(power_df, :value => ByRow(Float32); renamecols=false)
    power_df = innerjoin(power_df, select(signals, :subject, :date, :recording),
                         on=:recording)

    # subjects decided by Jay to be included the figure after reviewing
    # preliminary 6-subject figs
    key_subjects = ["001", "004", "005"]
    subset!(power_df, :subject => ByRow(x -> in(x, key_subjects)))

    # limit some usable recording time based on manual review in the portal
    # There's a ton of noise in some of these recordings,
    # and only a couple of key subjects
    noisy_005 = UUID("4fd957ff-088e-4e11-889c-f9003fbf9730")
    noisy_005_span = TimeSpan(Minute(68), Minute(76))
    noisy_004 = UUID("bea557df-6f07-48a5-b79b-68e71a8ccf5f")
    noisy_001 = UUID("5f700f27-da8b-48a8-94e7-3e39d9feb780")
    noisy_recs = [noisy_001, noisy_004, noisy_005]
    noisy_004_span = TimeSpan(Minute(0), Minute(8))
    subset!(power_df, [:recording, :span] => 
            ByRow((r, sp) -> 
                !in(r, noisy_recs) ||
                (r == noisy_005 && TimeSpans.contains(noisy_005_span, sp)) ||
                (r == noisy_004 && TimeSpans.contains(noisy_004_span, sp))))

    # add per-subject color
    color_df = DataFrame(:subject => ["001", "004", "005"],
                        :color => [CMAP[1], CMAP[2], CMAP[3]])
    power_df = innerjoin(power_df, color_df, on=:subject)

    # convert date to day after first recording to be shown
    first_date_df = combine(groupby(power_df, :subject),
                            :date => first => :first_date)
    power_df = innerjoin(power_df, first_date_df, on=:subject)
    transform!(power_df, [:date, :first_date] =>
               ByRow((b, a) -> "Day $(Dates.value(b - a) + 1)") => :date_label)

    relative_power_df = combine(groupby(power_df,
                                        [:recording, :span, :region, :subject,
                                         :date, :date_label, :color]),
                                :value => (x -> x / sum(x)) => :relative_value, 
                                :band => identity => :band)
    # compute log(power) after computing relative power
    transform!(power_df, :value => ByRow(log); renamecols=false)

    for band in ["delta", "theta", "alpha", "beta"]
        # plot log(power)
        band_df = subset(power_df, [:band, :region] =>
                         ByRow((b, r) -> b == band && r == "total"))
        power_fig, power_axis = raincloud_power_plot(band_df, :value)
        power_axis.ylabel = string("log(", band, " power)")
        fname = string(band, "_power_rain.png")
        save_figure(fname, power_fig)
        
        # plot relative power
        r_band_df = subset(relative_power_df, [:band, :region] =>
                           ByRow((b, r) -> b == band && r == "total"))
        power_fig, power_axis = raincloud_power_plot(r_band_df, :relative_value)
        power_axis.ylabel = string("Relative ", band, " power")
        fname = string("relative_", band, "_power_rain.png")
        save_figure(fname, power_fig)
    end
    return nothing
end

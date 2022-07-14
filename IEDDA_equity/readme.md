Background: Increasing evidence suggests that race affects EEG data collection for a variety of reasons, including access to care, hair type, hair style, and other biases.

Hypothesis: Algorithms will be inherently biased because training data lacks representation from certain races. Additionally, in some cases when racially disparate data is available, certain races may be more likely to be excluded if EEG data quality is inherently worse for those groups

Question: Is IEDDA racially biased?

To do:

-[x] assess the racial distribution of IEDDA training set

TEST set:
 "race"                                          "count"
 "Black or African American"                   37
 "Asian"                                       33
 "White"                                       49
 "Other"                                       44
 "White or Caucasian"                         480
 "Hispanic or Latino"                          13
 "American Indian or Alaska Native"             2
 "Native Hawaiian or Other Pacific Islander"    0
 
 SPIKES set:
  "race"                                          "count"
 "Black or African American"                   65
 "Asian"                                       44
 "White"                                       75
 "Other"                                       72
 "White or Caucasian"                         715
 "Hispanic or Latino"                          17
 "American Indian or Alaska Native"             0
 "Native Hawaiian or Other Pacific Islander"    0
 
 CONTROLS set:
  "race"                                           "count"
 "Black or African American"                   395
 "Asian"                                       244
 "White"                                       394
 "Other"                                       369
 "White or Caucasian"                         4016
 "Hispanic or Latino"                           54
 "American Indian or Alaska Native"             11
 "Native Hawaiian or Other Pacific Islander"     3
 

-[ ] make 10 IEDDA data splits, balanced for races
Is this necessary? Can we first examine performance on the existing TEST set by demographic?
If necessary...
--How many controls and spikes in a set?
1:8?
--How large must a set be?
144 ok?
  4 of each race with spikes, 32 of each race from controls
  IF YES, can I repeat Asians in the conrtols?
  
--balanced races required? If no then splits could be larger... but then how do we justify the proportions?
  --include hispanic as a race? (it is an ethnicity, though plausible it has an impact)


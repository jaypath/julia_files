# 7/21/22 From Michelle

using AWSS3
using BOME
using DataFrames
using Legolas

save_path = S3Path("s3://project-pr-001-sandbox/new.bome.annotation.arrow")
Legolas.write(save_path, df, Legolas.Schema("bome.annotation@1")) #df is a dataframe or table


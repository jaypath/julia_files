#7-21-22 - from michelle

using AWSS3
using DataFrames
using Legolas


pathString = "s3://project-pr-001-sandbox/my.table.arrow"
example_path = S3Path(pathString)
my_table = DataFrame(Legolas.read(example_path; validate=false);       copycols=true)

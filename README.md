# Direct Age Standardization
## What is it?
A SAS macro that performs direct age standardization of event rates (i.e. incidence, mortality, etc.)

## How does it work?
The macro attempts to emulate the method described by the Association of Public Health Epidemiologists in Ontario (APHEO). See this PDF [document](http://core.apheo.ca/resources/indicators/Standardization%20report_NamBains_FINALMarch16.pdf).

## Setup
This macro is built to work with SAS versions `>= 9.4`. Installing the macro is a two-step process:
1. Connect to the code in this repository.
2. Bring the macro into your SAS session.

### 1. Connect to the code in the repository
Before you can work with the macros, you need to fetch the files form the repository.

```
filename macro URL "https://cdn.jsdelivr.net/gh/lanejames35/sas-age-standardization@master/ageStandardize.sas"
```
This will put the macro into a file reference named `macro` that you can bring into your SAS session. The use of the name `macro` in the example below is arbitrary and can be anything you want!

**Note** that running the filename statement above does not make the macros accessible to SAS automatically. The job of the filename statement is to create the connection to the file containing the macros. This allows you to reference multiple versions of Ribosome at the same time.

### 2. Bring the macro into your SAS session
Assuming that you successfully created a file reference to `macro`, as written above, you can now bring the macros into your SAS session.

```
%include macro;
```

That's it! You’re now ready to call up the macros!

## Example
Please copy the code below to give yourself an idea of the expected inputs.

```
filename macro URL "https://cdn.jsdelivr.net/gh/lanejames35/sas-age-standardization@master/ageStandardize.sas"

%include macro;

data study_data;
format age $char5. events 8. pop 8.;
input age$ events pop;
cards;
<1     37 1234
1-4    25 1678
5-9    23 1768
10-14  27 1769
15-19  47 1899
20-24  66 1902
25-29  122 1932
30-34  264 2121
35-39  443 2343
40-44  731 3003
45-49  1022 3134
50-54  1523 3683
55-59  2223 3693
60-64  3108 3214
65-69  3866 2524
70-74  3345 1543
75-79  2719 1242
80-84  1692 1099
85-89  906 935
90+    121 899
;
run;

%ageStandardize(
    data=studyData,
    ageVariable=age,
    numerator=events,
    denominator=pop
)
```

In our example above, the expected record layout of the input data looks like this:

```
-----------------------
| age | events | pop  | 
-----------------------
| <1  | 37     | 1234 |
| 1-4 | 25     | 1678 |
| 5-9 | 23     | 1768 |
.
.
.
| 90+ | 99     | 899 |
----------------------
```

This dataset has the following required columns:
1. `age` group as a string
2. `events` as the number of individuals with our condition of interest
3. `pop` as the total number of individuals in our study population

Let's call this dataset `studyData`. A call to the marco with this data would look like this:
```
%ageStandardize(
    data=studyData,
    ageVariable=age,
    numerator=events,
    denominator=pop
)
```

**Note** that we didn't specifiy a standard population. This macro uses the 2011 Canadian Population as the default. To use something else, create a dataset of population totals using a numeric single-year age. Then add the `standardPopulation` parameter in the macro call to refenence the new dataset. Finally, specifiy the column containing the population totals using the `standardPopulationAgeVariable` parameter.

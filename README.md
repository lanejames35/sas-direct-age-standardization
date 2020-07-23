# Direct Age Standardization
## What is it?
A SAS macro that performs direct age standardization of event rates (i.e. incidence, mortality, etc.)

## How does it work?
The macro attempts to emulate the method described by the Association of Public Health Epidemiologists in Ontario (APHEO). See this PDF (document)["http://core.apheo.ca/resources/indicators/Standardization%20report_NamBains_FINALMarch16.pdf"].

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

### 2. Bring the macro into your SAS session
Assuming that you successfully created a file reference to `macro`, as written above, you can now bring the macros into your SAS session.

```
%include macro;
```

That's it! You’re now ready to call up the macros!


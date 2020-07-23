/****
 * Direct Age Standardization
 * 2020-07-22
 */
%macro ageStandardize(
    printHelp,
    data=,
    ageVariable=,
    numerator=,
    denominator=,
    standardPopulation=canada2011,
    standardPopulationAgeVariable=pop2011,
    byGroupVariable=,
    where=,
);

/* Help message */
%if %upcase(&printHelp) = HELP %then %goto help_msg;
/* Parameter validation */
%if %length(&data) = 0 %then %do;
    %put ====================;
    %put An value for data is required.;
    %put Please check your macro call and try again.;
    %put Run %nrstr(%ageStandardize(help)) for help.;
    %put ====================;
    %goto exit;
%end;
%if %length(&ageVariable) = 0 %then %do;
    %put ====================;
    %put A value for ageVariable is required.;
    %put Please check your macro call and try again.;
    %put Run %nrstr(%ageStandardize(help)) for help.;
    %put ====================;
    %goto exit;
%end;
%if %length(&numerator) = 0 %then %do;
    %put ====================;
    %put A value for numerator is required.;
    %put Please check your macro call and try again.;
    %put Run %nrstr(%ageStandardize(help)) for help.;
    %put ====================;
    %goto exit;
%end;
%if %length(&denominator) = 0 %then %do;
    %put ====================;
    %put A value for denominator is required.;
    %put Please check your macro call and try again.;
    %put Run %nrstr(%ageStandardize(help)) for help.;
    %put ====================;
    %goto exit;
%end;
%if %length(&standardPopulation) = 0 %then %do;
    %put ====================;
    %put A value for standardPopulation is required.;
    %put Please check your macro call and try again.;
    %put Run %nrstr(%ageStandardize(help)) for help.;
    %put ====================;
    %goto exit;
%end;
%if %length(&standardPopulationAgeVariable) = 0 %then %do;
    %put ====================;
    %put A value for standardPopulationAgeVariable is required.;
    %put Please check your macro call and try again.;
    %put Run %nrstr(%ageStandardize(help)) for help.;
    %put ====================;
    %goto exit;
%end;

/* Create standard population */
%if %upcase(&standardPopulation) = CANADA2011 %then %do;
proc sql;
    create table canada2011
    (
        pop2011 int,
        age int
    );
    insert into canada2011(pop2011, age)
    values(376321,0)
    values(379990,1)
    values(383179,2)
    values(383741,3)
    values(375833,4)
    values(366757,5)
    values(361038,6)
    values(363440,7)
    values(358621,8)
    values(360577,9)
    values(365198,10)
    values(376458,11)
    values(379838,12)
    values(391245,13)
    values(405425,14)
    values(426802,15)
    values(440145,16)
    values(446524,17)
    values(455872,18)
    values(469609,19)
    values(479650,20)
    values(484077,21)
    values(470052,22)
    values(458775,23)
    values(461800,24)
    values(471522,25)
    values(475052,26)
    values(474287,27)
    values(475287,28)
    values(473693,29)
    values(479377,30)
    values(472955,31)
    values(462922,32)
    values(455951,33)
    values(456750,34)
    values(457914,35)
    values(458413,36)
    values(448563,37)
    values(450150,38)
    values(458047,39)
    values(480129,40)
    values(478010,41)
    values(475541,42)
    values(473014,43)
    values(479224,44)
    values(506180,45)
    values(541424,46)
    values(557834,47)
    values(562501,48)
    values(551970,49)
    values(558958,50)
    values(548847,51)
    values(536639,52)
    values(529913,53)
    values(516903,54)
    values(501158,55)
    values(493948,56)
    values(473623,57)
    values(451080,58)
    values(433281,59)
    values(424456,60)
    values(414501,61)
    values(405624,62)
    values(404282,63)
    values(401580,64)
    values(344130,65)
    values(317981,66)
    values(306903,67)
    values(292908,68)
    values(271018,69)
    values(257990,70)
    values(240638,71)
    values(230156,72)
    values(218638,73)
    values(206400,74)
    values(200626,75)
    values(190737,76)
    values(180672,77)
    values(176879,78)
    values(170424,79)
    values(163436,80)
    values(152274,81)
    values(138753,82)
    values(129386,83)
    values(117291,84)
    values(107226,85)
    values(96193,86)
    values(85051,87)
    values(73870,88)
    values(64399,89)
    values(54015,90)
    values(43307,91)
    values(31444,92)
    values(24184,93)
    values(18966,94)
    values(13842,95)
    values(9962,96)
    values(7109,97)
    values(4974,98)
    values(3260,99)
    values(5268,100)
    ;
quit;
%end;
/* Scan age groups */
/* Extract age groupings and convert them to logic statements */
proc sql noprint;
   select distinct &ageVariable
        ,case
         when index(&ageVariable,'-')>1 then cat('between ',tranwrd(&ageVariable,'-',' and '))
         when index(&ageVariable,'<')=1 then substr(&ageVariable,index(&ageVariable,'<'))
         when index(&ageVariable,'+')>0 then cat(">=",substr(&ageVariable,1,index(&ageVariable,'+')-1))
         end as logic
   into :groupings separated by " ", :logic separated by "#"
   from &data;
quit;

/* Count the number of age groups to apply */
%local idx word countAgeGroups;
%let idx = 1;
%let word = %qscan(&groupings, &idx, %srt( ));
%do %while(&word ne);
    %let idx = %eval(&idx + 1);
    %let word = %qscan(&groupings, &idx, %str( ));
%end;
%let countAgeGroups = %eval(&idx - 1);

/* Apply the groupings using the logic above */
proc sql noprint;
    create table standard as
    select case
        %do i=1 %to &countAgeGroups;
            %let result=%scan(&groupings,&i,%str( ));
            %let expression=%scan(&logic,&i,#);
            when age &expression then "&result"
        %end;
            else " "
            end as &ageVariable,
            sum(&standardPopulationAgeVariable) as sum_&standardPopulationAgeVariable
            from &standardPopulation
            group by &ageVariable
        ;
quit;

/* Sort age groups to facilitate the merge */
proc sort
    data = &data;
    by &ageVariable;
run;

/* Merge and calculate */
proc sql noprint;
    select sum(sum_&standardPopulationAgeVariable)
    into :total_std
    from standard
    ;
quit;

data mergedStandard;
   merge &data(in=ina) standard(in=inb);
   by &ageVariable;
   if ina and inb;

   w_i=sum_&standardPopulationAgeVariable/&total_std;

   ir_i=&numerator/&denominator;

   varpy_i=&numerator/(&denominator.**2);
run;

/* Sort again in the case of a by gorup */
proc sort
    data=mergedStandard;
    by &byGroupVariable &ageVariable;
run;

data ASRcalculation;
    set mergedStandard end=eof;
   /************************************
    * IRW=weighted incidence rate
    * VARPY=part of person-time variance
    * VARPYW=weighted person-time variance
    * SUMWI=sum of weights
    * CRDEN=crude denominator
    ***********************************/
   retain IRW VARPY VARPYW SUMWI CRNUM CRDEN;

    %if %length(&byGroupVariable) > 0 %then %do;
        by &byGroupVariable;
        if first.&byGroupVariable then
        do;
            IRW=0;
            VARPYW=0;
            VARPY=0;
            SUMWI=0;
            CRNUM=0;
            CRDEN=0;
        end;

        IRW = IRW + (W_I * IR_I);
        SUMWI = SUMWI + W_I;
        VARPY = VARPY + ((W_I**2) * VARPY_I);
        CRNUM = CRNUM + &numerator;
        CRDEN = CRDEN + &denominator;

        if last.&byGroupVariable then
        do;
        /********************************
            Crude incidence rate
        *******************************/
            CIR=CRNUM/CRDEN;

            VARPYW=VARPY/(SUMWI**2);

        /********************************
            95% CONFIDENCE LIMITS
        ********************************/
            LO95 = IRW - (1.96*SQRT(VARPYW));
            HI95 = IRW + (1.96*SQRT(VARPYW));
            output;
        end;
    %end;
    %else %do;
        if _N_ = 1 then do;
            IRW=0;
            VARPYW=0;
            VARPY=0;
            SUMWI=0;
            CRNUM=0;
            CRDEN=0;
        end;

        IRW = IRW + (W_I * IR_I);
        SUMWI = SUMWI + W_I;
        VARPY = VARPY + ((W_I**2) * VARPY_I);
        CRNUM = CRNUM + &numerator;
        CRDEN = CRDEN + &denominator;

        if eof then
        do;
        /********************************
            Crude incidence rate
        *******************************/
            CIR=CRNUM/CRDEN;

            VARPYW=VARPY/(SUMWI**2);

        /********************************
            95% CONFIDENCE LIMITS
        ********************************/
            LO95 = IRW - (1.96*SQRT(VARPYW));
            HI95 = IRW + (1.96*SQRT(VARPYW));
            output;
        end;
    %end;

    label CIR='Crude Incidence Rate'
        IRW='Age Standardized Incidence Rate'
        LO95='Lower 95% CI'
        HI95='Upper 95% CI'
    ;
run;
proc print noobs label;
    var &byGroupVariable CIR IRW LO95 HI95;
run;
%goto exit;
%help_msg:
    %put =================================;
    %put Direct Age Standardization;
    %put ;
    %put VERSION;
    %put 0.1.1;
    %put ;
    %put SYNTAX;
    %put %nrstr(%ageStandardize(<help ?>; <data=[Dataset Name]>, <ageVariable=[Column Name]>, <numerator=[Column Name], <demoninator=[Column Name]>, <standardPopulation=[Dataset Name]>, <standardPopulationAgeVariable=[Column Name]>, <scanAgeGroupsToMatch={YES | NO}>, <byGroupVariable=[Column Name]>, where=[Condition]));
    %put ;
    %put PARAMETERS;
    %put help: Use %nrstr(%ageStandardize(help)) to display this help message. Null otherwise.;
    %put data: Names the dataset used to perform the direct age standardization.;
    %put ageVariable: Names the column in "data" that contains the age data.;
    %put numerator: Names the column in "data" that conatins the number of people in the study population having a contidion of interest;
    %put denominator: Names the column in "data" that conatins the total number of people in the study population.;
    %put standardPopulation: Names the dataset used to weight the indicence rate.;
    %put standardPopulationAgeVariable: Names the column in "standardPopulation" that contains the age data.;
    %put byGroupVariable: Names the column used to split the data. Age standarization is calculated for each distinct level.;
    %put where: Filters the input data with the condition supplied.;
    %put ;
    %put ===================================;
%exit:
%mend;

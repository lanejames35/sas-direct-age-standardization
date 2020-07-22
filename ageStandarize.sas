/****
 *
 *
 */

/* Create standard population */
data canada2011;
input pop2011 age;
cards;
376321 0
379990 1
383179 2
383741 3
375833 4
366757 5
361038 6
363440 7
358621 8
360577 9
365198 10
376458 11
379838 12
391245 13
405425 14
426802 15
440145 16
446524 17
455872 18
469609 19
479650 20
484077 21
470052 22
458775 23
461800 24
471522 25
475052 26
474287 27
475287 28
473693 29
479377 30
472955 31
462922 32
455951 33
456750 34
457914 35
458413 36
448563 37
450150 38
458047 39
480129 40
478010 41
475541 42
473014 43
479224 44
506180 45
541424 46
557834 47
562501 48
551970 49
558958 50
548847 51
536639 52
529913 53
516903 54
501158 55
493948 56
473623 57
451080 58
433281 59
424456 60
414501 61
405624 62
404282 63
401580 64
344130 65
317981 66
306903 67
292908 68
271018 69
257990 70
240638 71
230156 72
218638 73
206400 74
200626 75
190737 76
180672 77
176879 78
170424 79
163436 80
152274 81
138753 82
129386 83
117291 84
107226 85
96193 86
85051 87
73870 88
64399 89
54015 90
43307 91
31444 92
24184 93
18966 94
13842 95
9962 96
7109 97
4974 98
3260 99
5268 100
;
run;

/* Scan age groups */
/* Extract age groupings and convert them to logic statements */
proc sql noprint;
   select distinct &age_var
        ,case
         when index(&age_var,'-')>1 then cat('between ',tranwrd(&age_var,'-',' and '))
         when index(&age_var,'<')=1 then substr(&age_var,index(&age_var,'<'))
         when index(&age_var,'+')>0 then cat(">=",substr(&age_var,1,index(&age_var,'+')-1))
         end as logic
   into :groupings separated by " ", :logic separated by "#"
   from &in;
quit;

/* Count the number of age groups to apply */
%let idx = 1;
%let word = %qscan(&groupings, &idx, "#");
%do %while(&word ne);
    %let idx = %eval(&idx + 1);
    %let word = %qscan(&groupings, &idx, "#");
%end;
%let countAgeGroups = %eval(&idx - 1);

/* Apply the groupings using the logic above */
proc sql noprint;
   create table &out as
   select case
         %do i=1 %to &countAgeGroups;
            %let result=%scan(&groupings,&i,%str( ));
            %let expression=%scan(&logic,&i,#);
            when age &expression then "&result"
         %end;
         else " "
        end as agecat,
         sum(pop2011) as population
         from &standardPopulation
         group by agecat
        ;
quit;

/* Merge and calculate */

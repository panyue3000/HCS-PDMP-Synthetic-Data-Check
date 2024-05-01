
title; footnote; libname _all_; filename _all_;
proc datasets library=work memtype=data kill; quit; run;
ods graphics off;

/****************************************************************************************
* PROJECT       : HCS
* PROGRAM NAME  : calculate_pmp_outcomes_v01_20191106
* DATE WRITTEN  : Nov 6, 2019
* DESCRIPTION   : Calculate outcomes 2.5.1., 2.7.1, and 2.13
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
****************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v02_20191213
* DATE          : Dec 13, 2019
* MODIFICATIONS : Major revisions to 2.13a, 2.13b, 2.13c, 2.13d
				  Major revisions to how residence is attributed
				  No longer limiting queries to records with an HCS community as residence.
					e.g. if an individual has 5 records in a month, 1 has a zip code in a non-HCS community and 4 have a zip code in one HCS community,
					all 5 records will be evaluated and attributed to the HCS community. 
				  Revision to age range so medication history in the final months of 17 years of age can inform which events are incident in the early months of 18 years of age. 
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
****************************************************************************************
****************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v03_20191217
* DATE          : Dec 17, 2019
* MODIFICATIONS : Fixed 2.7.1 to work with a character patient_id 
				  Added PROC EXPORTs at the bottom of the program to export the counts to an XLSX file with multiple worksheets
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
****************************************************************************************
****************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v04_20191219
* DATE          : Dec 19, 2019
* MODIFICATIONS : Removed a subset of buprenorphine medications and a subset of codeine medications from the opioid list to improve 2.13.
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v05_20200214
* DATE          : Feb 14, 2020
* MODIFICATIONS : Several major revisions:
					1) Allocating residence to last zip code of each time period
					2) Added moving quarters to 2.13C and 2.13D so monthly counts can be calculated
					3) Added outcomes 2.18(numerator and denominator) and 3.1
					4) Filled in zeros for time period/community combinations without an outcome (previously did not print an observation)
					5) Added a "complete" variable to indicate if a time period is complete. e.g. if every day of a year is not available, the year has a value of zero for complete.
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v06_20200224
* DATE          : Feb 24, 2020
* MODIFICATIONS : 	Modified the "continuous" macro so it processes one ID at a time at step 4. This is intended to make the program more efficient.
					Fixed an inconsequential typo in the continuous macro
					Added length statements to ensure patient_id is never truncated
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v07_20200313
* DATE          : March 13, 2020
* MODIFICATIONS : Changed tiebreaker in step_g to use the last four digits of the NDC number rather than first four.	
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v08_20200501
* DATE          : May 1, 2020
* MODIFICATIONS : 	1) Corrected an error that was limiting 2.13.B to episodes lasting >=31 days.
					2) Using new drug lists. These are now imported at the top of the program for easier replacement when updated lists become available.
					3) For meaure 2.13A and the composite measure 2.13, mark months, quarters, and years incomplete if there's not sufficient follow-up
						time to determine if episodes last 31 days.
					4) Added options  (nonotes nomprint nosymbolgen nosource) before the "call execute" steps to reduce the number of notes in the log.
					5) Removed an extraneous "group by patient_id" from the benzo_per_day macro. It had no effect.
					6) Changed step D from the SQL join to a merge to reduce processing time.
					7) Changed the variable names of the test data to better match the actual MA PMP variable names. There is a new spreadsheet of testing data.
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v09_20200506
* DATE          : May 6, 2020
* MODIFICATIONS : 1) Modifyied the options for what gets to printed to the log (removing all mprint and symbolgen options).
				  2) Changed the point in step 4 in the continuous macro where the ID-specific datasets are deleted. 
					 Keeping the datasets in the work folder for too long was taking too much disk space.
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v10_20200520
* DATE          : May 20, 2020
* MODIFICATIONS : 	Changed step 4 in the continuous macro to one large proc sql query. Running it seperately for each ID was 
					intended to reduce processing time but it was requiring too much memory in MA.
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v11_20200609
* DATE          : June 9, 2020
* MODIFICATIONS : 	The opioid NDC file now includes columns for MME, strength per unit, and long/short acting. The CDC file is no 
					longer needed. Changed the import of the opioid NDC file to reflect this and removed the import of the CDC file.
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v12_20200702
* DATE          : July 2, 2020
* MODIFICATIONS : 	1) Changing the complete flag so only the most recent month/quarter/year of 2.13.A and 2.13 are marked as incomplete;
					2) Adding measure 3.3
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v12.1_20200708
* DATE          : July 8, 2020
* MODIFICATIONS : 	1) Added option nospool because MA was getting and "YHQSRC/XZPWRIT failure" message described here:
						https://stackoverflow.com/questions/39011326/sas-the-internal-source-spool-file-has-been-truncated-yhqsrc-xzpwrit-failure
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
*****************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v13_20201015
* DATE          : October 15, 2020
* MODIFICATIONS : 	1) Filling in prior last non-missing residence in months where a patient does not fill a prescription. This will affect a 
						small proportion of monthly counts in 2.7.1, 2.13.C, 2.13.D and 3.1 where events from the prior 2 months can affect the 3rd month.
					2) Changing how 2.13.C, 2.13.D and 3.1 quarterly and yearly counts are tallied.
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
*****************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v14_20210521
* DATE          : May 21, 2021
* MODIFICATIONS : 	1) Adding stratification by age group
					2) Adding stratification by sex
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
*****************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v14.1_20210607
* DATE          : June 7, 2021
* MODIFICATIONS : 	1) Made some small changes to the stratification data steps. These changes will not affect the counts. V14 had some extra null rows
						printed in the XLSX and these changes aim to remove them.
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
******************************************************************************************
*****************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v14.2_20210706
* DATE          : July 6, 2021
* MODIFICATIONS : 	1) Made minor changes to the stratification SQL calls. These changes will not affect the counts. 
						V14 and V14.1 had some extra null rows printed in the XLSX and these changes aim to remove them.
						DOBs are now selected from ALL_RECORDS_STEP_F rather than PMP_DOBS. They are the same DOBs with fills <17 years of age removed.
					2) Changed data steps to process buprenorphine and opioid NDCs due to variable name changes in raw files.
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v14.3_20210805
* DATE          : August 5, 2021
* MODIFICATIONS : 	1) Adding reciprocal suppression
* PROGRAMMER    : Greg Patts (gpatts@bu.edu)
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v14.4_20211214
* DATE          : December 14, 2021
* MODIFICATIONS : 	1) Added workaround to convert character dates to numeric for MA (only affects MA-specific program)
* PROGRAMMER    : Greg Patts (gpatts@bu.edu);
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v14.5_20220304
* DATE          : March 4, 2022
* MODIFICATIONS : New drugs lists are all in one file now
* PROGRAMMER    : Greg Patts (gpatts@bu.edu);
******************************************************************************************
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v14.6_20220406
* DATE          : April 6, 2022
* MODIFICATIONS : The data from the NDC file provided by RTI that previously imported as numeric now imports as character. Change import.
* PROGRAMMER    : Greg Patts (gpatts@bu.edu);
******************************************************************************************
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v15_20220707
* DATE          : July 7, 2022
* MODIFICATIONS : Adding the evaluation year (July 2021 - June 2022) for all measures except 2.13 and 2.13 submeasures
* PROGRAMMER    : Greg Patts (gpatts@bu.edu);
******************************************************************************************
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v15.1_20220719
* DATE          : July 19, 2022
* MODIFICATIONS : Adding the evaluation year (July 2021 - June 2022) for 2.13 and 2.13 submeasures
						Fixing the evaluation year (July 2021 - June 2022) for measure 2.18 and 3.1 -- previously returned zeros 
* PROGRAMMER    : Greg Patts (gpatts@bu.edu);
******************************************************************************************
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v16_20220907
* DATE          : September 7, 2022
* MODIFICATIONS : Changing 3.3, 3.3.30, 3.3.100, 3.3.275 to count providers who prescribe buprenorphine to any patient in the database.
					Previously restricted to patients 18+ who lived in an HCS community at any point during the study period.
				  Including additional study years for the 2.5.1 outcome. 2.5.1 (lagged by 6 months) will be used as the denominator for 2.7.1. 
					The additional study years are needed because the denominator for 2.7.1's 2019 count will be the 20182019 (7/2018-6/2019) 5.1 count, for example.
* PROGRAMMER    : Greg Patts (gpatts@bu.edu);
******************************************************************************************
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v16.1_20221007
* DATE          : October 7, 2022
* MODIFICATIONS : Fixed study years for 2.5.1. Version 16 returned all zeros for 20172018, 20182019, 20192020, etc.
					Removed duplicate counts in the output for 3.3, 3.3.30, 3.3.100, and 3.3.275.
* PROGRAMMER    : Greg Patts (gpatts@bu.edu);
******************************************************************************************
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v16.2_20221108
* DATE          : November 8, 2022
* MODIFICATIONS : For the evaluation year (20212022) measures 2.13.A and 2.13 were incorrectly being flagged as incomplete (complete = 0). Fixed in this version. 
* PROGRAMMER    : Greg Patts (gpatts@bu.edu);
******************************************************************************************
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v17_20230628
* DATE          : June 28, 2023
* MODIFICATIONS : Added measure 3.4 [currently commented out] 
				  New NDC file has benzo NDCs as character variable with leading zeros
					Prior versions had benzo NDCs as numeric variables without leading zeros (requiring them to be added in this program)
* PROGRAMMER    : Greg Patts (gpatts@bu.edu);
******************************************************************************************/
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v17.1_20230807
* DATE          : August 7, 2023
* MODIFICATIONS : Measure 3.4 is no longer commented out
* PROGRAMMER    : Greg Patts (gpatts@bu.edu);
******************************************************************************************/
******************************************************************************************
* REVISED PROGRAM:calculate_pmp_outcomes_v18_20240419
* DATE          : April 19, 2024
* MODIFICATIONS : 	Changing measure 3.3 to include only patients 18+ years of age
					Changing measure 2.7.1 to include patients who reach 180 days and run out in the same month
					Changing threshold date of 2.7.1 from fill date +180 to fill date + 179
					Changing 2.18 to use the 17yo table. This will add a small number of additional opioid episodes.
					Fixing study year residence of 2.18 denominator -- was previously using 2022 residence rather than 20212022 residence
* PROGRAMMER    : Greg Patts (gpatts@bu.edu);
******************************************************************************************/





options nospool mergenoby=error;
%let rundate = %sysfunc(today(),yymmddn8.);


/********************************************************************************************************************/
/**************************Set the export path for the final dataset of counts by community**************************/
/********************************************************************************************************************/

%let export_path = C:\Users\panyue\Box\1 Healing Communities\Data Issues\1 1 1 1 Wave 2\Synthetic Data\Export;

/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/




/******************************************************************************/
/*******************Import list of waived providers from DEA*******************/
/******************************************************************************/


PROC IMPORT OUT= WORK.DEA0
            DATAFILE= "\\ad.bu.edu\bumcfiles\SPH\DCC\Dept\HCS\08Data\02Clean_Data\dea_registration\dea_waived_ma_20230106.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
	 GUESSINGROWS=10000;
RUN;


/******************************************************************************/
/******************************************************************************/
/******************************************************************************/



/**************************************************************************************************************/
/**************************Set the import path for the NDC lists and define filenames**************************/
/**************************************************************************************************************/

%let import_path = C:\Users\panyue\Box\1 Healing Communities\Data Issues\1 1 1 1 Wave 2\Synthetic Data\Files;



%let filename = KY Medispan Export 20230619.xlsx;


/*%let bup_file = bup ndc 6-28-21.xlsx;*/
/*%let opioid_file = opioid NDC 6-28-21.xlsx;*/
/*%let benzo_file = benzo list 9-23-2021.xlsx;*/






/*****************************************************************************************/
/*****************************************************************************************/
/*****************************************************************************************/


PROC IMPORT OUT= WORK.bup0
            DATAFILE= "&import_path/&filename" 
            DBMS=XLSX REPLACE;
     SHEET="Bup"; 
     GETNAMES=YES;
RUN;

proc sql;
create table bup as
select unique NDC_UPC_HRI as ndc_char label = 'ndc_char'
from bup0
where NDC_UPC_HRI ne '';
quit;

/*****************************************************************************************/

PROC IMPORT OUT= WORK.benzo0
            DATAFILE= "&import_path/&filename" 
            DBMS=XLSX REPLACE;
     SHEET="Benzo"; 
     GETNAMES=YES;
RUN;

proc sql;
create table benzo as
/*select unique  put(NDC_UPC_HRI,z11.) as ndc_char label = 'ndc_char'*/
select unique NDC_UPC_HRI as ndc_char label = 'ndc_char'

from benzo0
/*where ndc_upc_hri ne .;*/
where ndc_upc_hri ne '';
quit;


/*****************************************************************************************/

PROC IMPORT OUT= WORK.opioid0
            DATAFILE= "&import_path/&filename" 
            DBMS=XLSX REPLACE;
     SHEET="Op"; 
     GETNAMES=YES;
RUN;

data opioid1;
set opioid0;
where ndc_upc_hri ne '';

ndc_char = ndc_upc_hri;

if longshortacting = 'LA' then long_act = 1;
if longshortacting = 'SA' then long_act = 0;

mme_conversion_factor_char = mme_conversion_factor;
strength_per_unit_char = strength_per_unit;


keep ndc_char 
	 long_act
	 mme_conversion_factor_char
	 strength_per_unit_char;
run;

data opioid2;
set opioid1;
mme_conversion_factor = mme_conversion_factor_char + 0;
strength_per_unit = strength_per_unit_char + 0;

drop mme_conversion_factor_char strength_per_unit_char;
run;


proc sql;
create table opioid as 
select unique *
from opioid2;
quit;





/*********************************************************************************************/
/*Read in PMP data*/
/*********************************************************************************************/

PROC IMPORT OUT= WORK.pmp_all
            DATAFILE= "\\ad.bu.edu\bumcfiles\SPH\DCC\Dept\HCS\09SAS_Programs\01Dataset_Creation\20190903_create_pmp_outcomes\example_data\renamed_fake_pmp_data.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="Sheet1$"; 
     GETNAMES=YES;
     MIXED=Yes;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;






/*********************************************************************************************/
/*********************************************************************************************/
/*********************************************************************************************/
/*Step A:Create macro variables that contain the start date and end date of the data being 
analyzed. If the beginning of the study period is January 1, 2018, the start date of the 
data analyzed should be July 1, 2017 because six months of records are needed for look-back. 
The end date should not exceed the date of the available complete PMP data.
/*********************************************************************************************/
%let start_date = mdy(01,01,2017); /*changed july 2017 to jan 2017 on 20220907 -- this is 6 months prior to start of study year 20172018*/ 
%let end_date = mdy(12,31,2023);
/*********************************************************************************************/
/*********************************************************************************************/
/*********************************************************************************************/
/*********************************************************************************************/





/********************************************************************************************************************************************/
/*Create a dataset that has every date in the date range. This will be used below for a "call execute" to query each possible day separately*/
/********************************************************************************************************************************************/
data date_range;
do date=&start_date to &end_date;
output;
end;
format date date9.;
run;

data for_first_and_last;
set date_range;
month=month(date);
year=year(date);
run;

proc sort data=for_first_and_last; by year month date; run;

data first_and_last; set for_first_and_last; by year month date;
if not first.month and not last.month then delete;
drop month year;
run;



proc sql; /*new 20240419*/
create table month_start_end as
select distinct
month(date) as month,
year(date) as year,
min(date) as start format date9.,
max(date) as end format date9.
from first_and_last
group by month(date), year(date)
order by year, month;
quit;


/********************************************************************************************************************************************/
/********************************************************************************************************************************************/
/********************************************************************************************************************************************/



/*********************************************************************************************/
/*Step B: Create a table of HCS communities. Include any information you will need in order to */
/*join this table with the PMP data (ZIP codes, city/town names, county names, etc.).*/
/*********************************************************************************************/

libname zips '\\ad.bu.edu\bumcfiles\SPH\DCC\Dept\HCS\08Data\02Clean_Data\zip_code_list';

data zips0; 
length community $100;
set zips.zip_code_list_20200103; 
run;


proc sql;
create table zips as
select unique put(zip,z5.) as zip_char,
			  community format $100.,
			  1 as hcs
from zips0;
quit;
/*********************************************************************************************/
/*********************************************************************************************/
/*********************************************************************************************/



/********************************************************************************************************************************************/
/*Identify time periods that are fully included in the date range*/
/********************************************************************************************************************************************/
proc sql;
create table months0 as
select unique 	year(date) as year,
				month(date) as month,
				count(date) as days
from date_range
group by year, month;
quit;

proc sql;
create table quarters0 as
select unique 	year(date) as year, 
				qtr(date) as quarter, 
				count(date) as days
from date_range
group by year, quarter;
quit;

proc sql;
create table years0 as
select unique 	year(date) as year, 
				count(date) as days
from date_range
group by year;
quit;

/****************************/
/********new 20220603********/
/****************************/

%macro study_year(start,end);
proc sql;
create table study_year_&start.&end. as
select unique 	&start.&end. as year,
				count(date) as days
from date_range
where 	date ge mdy(07,01,&start) and
		date le mdy(06,30,&end);
quit;
%mend study_year;

%study_year(2017,2018);
%study_year(2018,2019);
%study_year(2019,2020);
%study_year(2020,2021);
%study_year(2021,2022);
%study_year(2022,2023);
%study_year(2023,2024);
%study_year(2024,2025);


data years1;
set years0 study_year_:;
where days ne 0;
run;

/****************************/
/****************************/
/****************************/



data months;
set months0;
if month in (1,3,5,7,8,10,12) then do;
	if days lt 31 then complete = 0;
	if days eq 31 then complete = 1;
end;

if month in (4,6,9,11) then do;
	if days lt 30 then complete = 0;
	if days eq 30 then complete = 1;
end;


if month = 2 and mod(year,4) eq 0 then do;
	if days lt 29 then complete = 0;
	if days eq 29 then complete = 1;
end;

if month = 2 and mod(year,4) ne 0 then do;
	if days lt 28 then complete = 0;
	if days eq 28 then complete = 1;
end;
run;

data quarters;
set quarters0;
if quarter = 1 and mod(year,4) eq 0 then do; 
	if days lt 91 then complete = 0;
	if days eq 91 then complete = 1;
end;

if quarter = 1 and mod(year,4) ne 0 then do;
	if days lt 90 then complete = 0;
	if days eq 90 then complete = 1;
end;

if quarter = 2 then do;
	if days lt 91 then complete = 0;
	if days eq 91 then complete = 1;
end;

if quarter in (3,4) then do;  
	if days lt 92 then complete = 0;
	if days eq 92 then complete = 1;
end;
run;

data years;
set years1;
if mod(year,4) eq 0 then do; 
	if days lt 366 then complete = 0;
	if days eq 366 then complete = 1;
end;

if mod(year,4) ne 0 then do; 
	if days lt 365 then complete = 0;
	if days eq 365 then complete = 1;
end;

run;


/*create lists of all combinations of communities and time periods to assign zeros*/
proc sql;
create table all_possible_y as
select unique 	a.community, 
				b.year,
				b.complete
from zips a, years b
where b.year ge 2018
order by community, year;
quit;

proc sql;
create table all_possible_q as
select unique 	a.community,
				b.year,
				b.quarter,
				b.complete
from zips a, quarters b
where b.year ge 2018
order by community, year, quarter;
quit;

proc sql;
create table all_possible_m as
select unique 	a.community,
				b.year,
				b.month,
				b.complete
from zips a, months b
where b.year ge 2018
order by community, year, month;
quit;






/********************************************************************************************************************************************/
/********************************************************************************************************************************************/
/********************************************************************************************************************************************/







/*******************************************************************************************/
/*Step C: From the PMP database, select the IDs of all patients who filled a prescription***/
/*while a resident of an HCS community between the dates defined in step A. ****************/
/*******************************************************************************************/

proc sql;
create table pmp_hcs_temp as
select unique a.uid as patient_id label = 'Patient ID' length=1000,
			  a.dspfilldate as date_filled format date9. label = 'Date filled',
			  b.community
from pmp_all a, zips b
where a.pmppatzipfirst5 = b.zip_char and 
	  a.dspfilldate ge &start_date and 
	  a.dspfilldate le &end_date
;
quit;

proc sql;
create table pmp_hcs_ids as
select unique patient_id length=100
from pmp_hcs_temp;
quit;





/*******************************************************************************************/
/*******************************************************************************************/
/*******************************************************************************************/

/*****************************************************************************/
/*Step D: Select all PMP records of the patients selected in step C,**********/
/*regardless of the residence on the individual records.**********************/
/*****************************************************************************/



/*proc sql;*/
/*create table all_records_step_d as*/
/*select unique a.uid as patient_id label = 'Patient ID' length = 100,*/
/*			  a.dspfilldate as date_filled format date9. label = 'Date filled',*/
/*			  year(a.dspfilldate) as year_filled label = 'Year filled',*/
/*			  qtr(a.dspfilldate) as quarter_filled label = 'Quarter filled',*/
/*			  month(a.dspfilldate) as month_filled label = 'Month filled', */
/*			  a.pmppatzipfirst5 as zip_char label = 'ZIP code',*/
/*			  a.patbirthdate as dob_inc_missing format date9. label = 'DOB (including missing values)',*/
/*			  a.dspndc as ndc11_char label = 'NDC',*/
/*			  a.preDEA as dea_prescriber label = 'Prescriber DEA number',*/
/*			  a.phaDEA as dea_pharmacy label = 'Pharmacy DEA number',*/
/*			  a.dspquantity as quantity_dispensed label = 'Quantity dispensed',*/
/*			  a.dspdayssupply as days_dispensed label = 'Days dispensed',*/
/*			  (a.dspfilldate + (a.dspdayssupply - 1)) as date_run_out format date9. label = 'Run-out date'*/
/*from pmp_all a, pmp_hcs_ids b*/
/*where a.uid = b.patient_id and */
/*	  a.dspfilldate ge &start_date and */
/*	  a.dspfilldate le &end_date*/
/*;*/
/*quit;*/



data pmp_all; 
set pmp_all;
length patient_id $100;
patient_id = uid;
run;

proc sort data=pmp_all; by patient_id; run;
proc sort data=pmp_hcs_ids; by patient_id; run;


data all_records_step_d;
merge pmp_hcs_ids (in=a) pmp_all (in=b); by patient_id;
if a and b;

date_filled = dspfilldate;
year_filled = year(dspfilldate);
quarter_filled = qtr(dspfilldate);
month_filled = month(dspfilldate);
/*new 20200625*/
date_written = dspdatewritten; 
year_written = year(dspdatewritten);
month_written = month(dspdatewritten);
/**************/
zip_char = pmppatzipfirst5;
dob_inc_missing = patBirthDate;
ndc11_char = dspNDC;
dea_prescriber = preDEA;
dea_pharmacy = phaDEA; 
quantity_dispensed = dspQuantity;
days_dispensed = dspDaysSupply;
date_run_out = (date_filled + (days_dispensed - 1));


/********************************************************************/
/***************************added 20210517***************************/
/********************************************************************/

/*in MA the patGender variable can have values M, F, and U.*/
if upcase(patgender) in ('M') then sex_for_strat = 'Sex: M';
if upcase(patgender) in ('F') then sex_for_strat = 'Sex: F';
if upcase(patgender) in ('U') then sex_for_strat = 'Sex: U';
if upcase(patgender) not in ('M','F','U') then sex_for_strat = 'Sex: X'; /*null and any other values*/

/********************************************************************/
/********************************************************************/
/********************************************************************/


label patient_id = 'Patient ID';
label date_filled = 'Date filled';
label year_filled  = 'Year filled';
label quarter_filled = 'Quarter filled';
label month_filled  = 'Month filled';
/*new 20200625*/
label date_written = 'Date written';
label year_written  = 'Year written';
label month_written  = 'Month written';
/**************/
label zip_char = 'ZIP code';
label dob_inc_missing = 'DOB (including missing values)';
label ndc11_char = 'NDC';
label dea_prescriber = 'Prescriber DEA number';
label dea_pharmacy = 'Pharmacy DEA number';
label quantity_dispensed = 'Quantity dispensed';
label days_dispensed = 'Days dispensed';
label date_run_out = 'Run-out date';

format date_filled date_run_out date_written date9.;

if date_filled lt &start_date then delete;
if date_filled gt &end_date then delete;

keep 
patient_id
date_filled 
year_filled 
quarter_filled 
month_filled 
/*new 20200625*/
date_written
year_written
month_written
/**************/
zip_char 
dob_inc_missing 
ndc11_char
dea_prescriber 
dea_pharmacy 
quantity_dispensed
days_dispensed 
date_run_out
sex_for_strat

;

run;








/********************************************************************************************************************************************/
/*Step E. Select unique combinations of patient ID and date of birth from the table created in step D where date of birth */
/*is not null. For each patient ID, keep one record with the most frequent date of birth for that patient. */
/*Using this date of birth throughout will enable us to use records with missing dates of birth and to avoid deleting */
/*records with date of birth typos or a missing date of birth. */
/********************************************************************************************************************************************/

proc sql;
create table pmp_dobs_temp as 
select unique 	patient_id length = 100,
				dob_inc_missing as dob label = 'Date of birth' format date9., 
				count(dob) as dob_frequency
from all_records_step_d
where dob_inc_missing ge mdy(01,01,1900)
group by patient_id, dob
order by patient_id, dob_frequency desc, dob desc;
quit;


data pmp_dobs; set pmp_dobs_temp; by patient_id descending dob_frequency descending dob;
if not first.patient_id then delete;

year_18yo = 18 + year(dob);
qtr_dob = qtr(dob);
month_dob = month(dob);

drop dob_frequency;
run;


/************************************************************************/
/************************************************************************/
/************************************************************************/
/************************************************************************/





/********************************************************************************************************************************************/
/********************************************************************************************************************************************/
/********************************************************************************************************************************************/



/*********************************************************************************************************************************/
/*Step F.Join the tables created in steps D and E. Calculate the age of the patient on the date of each prescription fill. */
/*Delete records where the patient is younger than 17 years of age. Also delete records where the patient is younger */
/*than 18 years of age on the end date defined in step A. Calculate the month and year in which each patient turned */
/*18 years of age. Results below will be calculated for patients =18 years of age in the month that is being evaluated. */
/*The records from the year in which patients are 17 years of age will be used for look-back.*/
/*********************************************************************************************************************************/

proc sql;
create table all_records_step_f as
select 	a.*,  
		b.dob,
		b.year_18yo,
		b.qtr_dob,
		b.month_dob,
		int(yrdif(b.dob, a.date_filled,'ACTUAL')) as age_at_fill,
		substr(a.ndc11_char,8,4) as ndc_last_4digits
from all_records_step_d a, pmp_dobs b
where 	a.patient_id = b.patient_id and 
		int(yrdif(b.dob, a.date_filled,'ACTUAL')) ge 17
;
quit;






/*********************************************************************************************/
/***************************** NEW MAY 2021  - MODIFIED SEPT 2022*****************************/
/*******************************CREATE STRATIFICATION TABLES**********************************/
/*********************************************************************************************/

data strat_periodx; x = 0; run;

proc sql;
create table strat_periods as
		select 'YEAR 20172018' as period, mdy(07,01,2017) as start_date format date9., mdy(6,30,2018) as end_date format date9. from strat_periodx
		union all
select 'YEAR 2018' as period, mdy(01,01,2018) as start_date format date9., mdy(12,31,2018) as end_date format date9. from strat_periodx
union all
		select 'YEAR 20182019' as period, mdy(07,01,2018) as start_date format date9., mdy(6,30,2019) as end_date format date9. from strat_periodx
		union all
select 'YEAR 2019' as period, mdy(01,01,2019) as start_date format date9.,  mdy(12,31,2019) as end_date format date9. from strat_periodx
union all
		select 'YEAR 20192020' as period, mdy(07,01,2019) as start_date format date9., mdy(6,30,2020) as end_date format date9. from strat_periodx
		union all
select 'YEAR 2020' as period, mdy(01,01,2020) as start_date format date9.,  mdy(12,31,2020) as end_date format date9. from strat_periodx
union all
		select 'YEAR 20202021' as period, mdy(07,01,2020) as start_date format date9.,  mdy(6,30,2021) as end_date format date9. from strat_periodx
		union all
select 'YEAR 2021' as period, mdy(01,01,2021) as start_date format date9.,  mdy(12,31,2021) as end_date format date9. from strat_periodx
union all
		select 'YEAR 20212022' as period, mdy(07,01,2021) as start_date format date9.,  mdy(6,30,2022) as end_date format date9. from strat_periodx
		union all
select 'YEAR 2022' as period, mdy(01,01,2022) as start_date format date9.,  mdy(12,31,2022) as end_date format date9. from strat_periodx
union all
		select 'YEAR 20222023' as period, mdy(07,01,2022) as start_date format date9.,  mdy(6,30,2023) as end_date format date9. from strat_periodx
		union all
select 'YEAR 2023' as period, mdy(01,01,2023) as start_date format date9.,  mdy(12,31,2023) as end_date format date9. from strat_periodx
union all
		select 'YEAR 20232024' as period, mdy(07,01,2023) as start_date format date9.,  mdy(6,30,2024) as end_date format date9. from strat_periodx
		union all
select 'YEAR 2024' as period, mdy(01,01,2024) as start_date format date9.,  mdy(12,31,2024) as end_date format date9. from strat_periodx
union all
		select 'YEAR 20242025' as period, mdy(07,01,2024) as start_date format date9.,  mdy(6,30,2025) as end_date format date9. from strat_periodx
;
quit;


proc sql; 
create table strat_age0 as 
select unique  	a.period,
				a.end_date,
				b.patient_id,
				b.dob,
				int(yrdif(b.dob, a.end_date,'ACTUAL')) as age_for_strat
from strat_periods a, all_records_step_f b
order by patient_id, end_date;
quit;



data strat_age;
set strat_age0;
/*********new 20210716*********/
if age_for_strat lt 18 then delete;
/******************************/
if 18 le age_for_strat le 34 then age_cat_for_strat = 'Age 18-34';
if 35 le age_for_strat le 54 then age_cat_for_strat = 'Age 35-54';
if 55 le age_for_strat then age_cat_for_strat = 'Age 55+';
run;





proc sql;
create table strat_sex0 as 
select unique b.patient_id,
			  a.end_date,
			  a.period,
			  max(b.date_filled) as max_fill_prior_to_end format date9.
from strat_periods a, all_records_step_f b
where b.date_filled le a.end_date  
group by patient_id, end_date, period;
quit;


proc sql;
create table strat_sex1 as 
select unique b.patient_id,
			  a.end_date,
			  a.period,
			  min(b.date_filled) as min_fill_after_end format date9.
from strat_periods a, all_records_step_f b
where b.date_filled ge a.end_date  
group by patient_id, end_date, period;
quit;

data strat_sex2; merge strat_sex0 strat_sex1; by patient_id end_date period; 

if max_fill_prior_to_end ne . then date_for_strat_sex = max_fill_prior_to_end;
if max_fill_prior_to_end eq . then date_for_strat_sex = min_fill_after_end;

format date_for_strat_sex date9.;

run;



proc sql;
create table strat_sex3 as 
select unique a.patient_id,
			  a.end_date,
			  a.period,
			  b.sex_for_strat
from strat_sex2 a, all_records_step_f b
where a.patient_id = b.patient_id and 
	  a.date_for_strat_sex = b.date_filled;
quit;



/*in rare cases in which a patient has >1 fills on the final fill before the end of the stratification */
/*and those prescriptions have >1 genders, this prioritizes gender in alphabetical order*/
/*F (female) > M (male) > U (unknown) >X (missing)*/
proc sort data=strat_sex3; by patient_id end_date sex_for_strat; run;

data strat_sex; set strat_sex3; by patient_id end_date sex_for_strat; 
if not first.end_date then delete;
run;


proc sort data=strat_age; by patient_id period end_date; run;
proc sort data=strat_sex; by patient_id period end_date; run;


data strat; merge strat_age(in=a) strat_sex(in=b); by patient_id period end_date; 
if a; /*strat_sex has more records than strat_age because <18 ages are deleted from strat_age*/

if period = 'YEAR 20172018' then year_for_join = 20172018;
if period = 'YEAR 2018' 	then year_for_join = 2018;
if period = 'YEAR 20182019' then year_for_join = 20182019;
if period = 'YEAR 2019' 	then year_for_join = 2019;
if period = 'YEAR 20192020' then year_for_join = 20192020;
if period = 'YEAR 2020' 	then year_for_join = 2020;
if period = 'YEAR 20202021' then year_for_join = 20202021;
if period = 'YEAR 2021' 	then year_for_join = 2021;
if period = 'YEAR 20212022' then year_for_join = 20212022;
if period = 'YEAR 2022' 	then year_for_join = 2022;
if period = 'YEAR 20222023' then year_for_join = 20222023;
if period = 'YEAR 2023' 	then year_for_join = 2023;
if period = 'YEAR 20232024' then year_for_join = 20232024;
if period = 'YEAR 2024' 	then year_for_join = 2024;
if period = 'YEAR 20242025' then year_for_join = 20242025;

drop dob end_date age_for_strat;

run;


/*create this to zero-fill counts*/
proc sql;
create table all_possible_strat as 
select * 
from all_possible_y,
	(select unique age_cat_for_strat as strat, 'AGE' as strat_type length=10 from strat
	union all  
	select unique sex_for_strat as strat, 'SEX' as strat_type length=10 from strat);
quit;






/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/


/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

/*Step G.	From records with non-missing residences in the table created in step F, for each patient in each month */
/*that the patient filled a prescription, select the patient ID, month of the fill, quarter of the fill, year */
/*of the fill, and the patient's residence associated with their final fill (latest fill date) in each month. */
/*Select residences regardless of whether or not they are HCS communities. */
/**/
/*If a patient has two or more fills on the patient's last fill date of the month and those fills are associated */
/*with two or more residences, select the first record when sorting by the following variables:*/
/* */
/*a.	Descending binary variable that indicates if the residence is an HCS community (giving preference to HCS communities over non-HCS communities).*/
/*b.	Descending days supplied (giving preference to records with greater days supplied)*/
/*c.	Ascending NDC number*/
/*d.	Ascending prescriber DEA number*/
/**/
/*This residence is each patient's final residence for each month, regardless of whether or not it is an HCS community.*/

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

proc sort data=all_records_step_f; by zip_char; run;
proc sort data=zips; by zip_char; run;

data step_g_temp1; merge all_records_step_f(in=a) zips (in=b); by zip_char; 
if a;
if not b then do;
	hcs = 0;
	community = '***NOT AN HCS COMMUNITY';
end;
run;

data step_g_temp2;
set step_g_temp1;
if zip_char in ('','99999') then delete; /*delete observations with missing zips, just for this step where we're selecting residences*/
run;

proc sort data=step_g_temp2; 
by 	patient_id 
	year_filled 
	month_filled 
	descending date_filled 
	descending hcs
	descending days_dispensed
	ndc_last_4digits
	dea_prescriber;
run;

data step_g_temp3;
set step_g_temp2;
by 	patient_id 
	year_filled 
	month_filled 
	descending date_filled 
	descending hcs
	descending days_dispensed
	ndc_last_4digits
	dea_prescriber;
if not first.month_filled then delete;
run;

proc sql;
create table step_g_temp4 as
select unique patient_id, 
			  year_filled as year, 
			  quarter_filled as quarter,
			  month_filled as month,
			  community,
			  hcs
from step_g_temp3;
quit;

/*proc contents data=step_g_temp4; run;*/


/*New in version 13.*/
/*Filling in prior last non-missing residence */
/*in months where a patient does not fill a prescription.*/



proc sql;
create table all_possible_id_month
as select a.patient_id,
			b.year,
			b.month
from pmp_hcs_ids a, months b
order by a.patient_id, b.year, b.month;
quit;


data step_g_temp5; merge all_possible_id_month step_g_temp4; by patient_id year month; 

if month in (1,2,3) then quarter = 1;
if month in (4,5,6) then quarter = 2;
if month in (7,8,9) then quarter = 3;
if month in (10,11,12) then quarter = 4;

run;

proc sort data=step_g_temp5; by patient_id year month; run;

data step_g_step6; set step_g_temp5; by patient_id year month; 
retain _community _hcs;

if first.patient_id then _community = community;
if not missing(community) then _community=community;
else community = _community;

if first.patient_id then _hcs = hcs;
if not missing(hcs) then _hcs=hcs;
else hcs = _hcs;

drop _community _hcs;

run;

data step_g; set step_g_step6; 
if community = '' then delete;
run;







/*Step H.	From the table generated in step G, select the patient ID and residence for the maximum available */
/*month in each calendar quarter (e.g. if a patient filled prescriptions in January 2018 and February 2018*/
/*but not in March 2018, the February 2018 residence will be the Q1 2018 residence). These residences reflect */
/*each patient's final residence for each quarter, regardless of whether or not it is an HCS community.*/


proc sql;
create table step_h_temp as 
select 	patient_id,
		year,
		quarter,
		max(month) as max_month_in_quarter
from step_g
group by patient_id, year, quarter;
quit;

proc sql;
create table step_h as
select 	a.patient_id,
		a.year,
		a.quarter,
		a.community,
		a.hcs
from step_g a, step_h_temp b
where 	a.patient_id = b.patient_id and 
		a.year = b.year and
		a.quarter = b.quarter and 
		a.month = b.max_month_in_quarter;
quit;


/*Step I. From the table generated in step G, select the patient ID, residence combination for the maximum available */
/*month of each year. This residence reflects each patient's final residence for each year, regardless of whether */
/*or not it is an HCS community.*/


proc sql;
create table step_i_temp as 
select 	patient_id,
		year,
		max(month) as max_month_in_year
from step_g
group by patient_id, year;
quit;

proc sql;
create table step_i as
select 	a.patient_id,
		a.year,
		a.community,
		a.hcs
from step_g a, step_i_temp b
where 	a.patient_id = b.patient_id and 
		a.year = b.year and
		a.month = b.max_month_in_year;
quit;



/*Step J. From the table created in step G, delete the rows where the patient's residence is not an HCS community. */
/*The remaining monthly residences will be used when the patient is included in monthly counts. */
data step_j; set step_g; where hcs = 1; drop hcs; run;

/*Step K. From the table created in step H, delete the rows where the patient's residence is not an HCS community. */
/*The remaining quarterly residences will be used when the patient is included in quarterly counts.*/
data step_k; set step_h; where hcs = 1; drop hcs; run;

/*Step L. From the table created in step I, delete the rows where the patient's residence is not an HCS community. */
/*The remaining yearly residences will be used when the patient is included in yearly counts.*/
data step_L_0; set step_i; where hcs = 1; drop hcs; run;


/***************************/
/*******new 20220603********/
/***************************/
/*The residence of the evaluation year is the Q2 2022 residence*/
/*modified 20220906*/

data step_L_1temp;
set step_k;
where quarter = 2;
year_orig = year;
drop year;
run;

data step_L_1;
set step_L_1temp;

if year_orig = 2017 then year = 20162017;
if year_orig = 2018 then year = 20172018;
if year_orig = 2019 then year = 20182019;
if year_orig = 2020 then year = 20192020;
if year_orig = 2021 then year = 20202021;
if year_orig = 2022 then year = 20212022;
if year_orig = 2023 then year = 20222023;
if year_orig = 2024 then year = 20232024;
if year_orig = 2025 then year = 20242025;

drop year_orig quarter;
run;



data step_L;
set step_L_0 step_L_1;
run;
proc sort data=step_L; by patient_id year; run;
/***************************/
/***************************/
/***************************/




/*********************************************************************************************/
/*********************************************************************************************/
/*********************************************************************************************/


/**************************************************************************************************************************************************/
/*Step M. From the table created in step F, use the HCS Approved dataset to select all filled prescriptions for buprenorphine */
/*or buprenorphine/naloxone products approved by the FDA for treatment of OUD. Exclude transdermal buprenorphine and Belbuca */
/*as these are indicated for pain.*/
/**************************************************************************************************************************************************/

proc sql;
create table hcs_bup_17 as /*to be used for measures that require look-back*/
select unique * 
from all_records_step_f a, bup b
where a.ndc11_char = b.ndc_char and 
		a.age_at_fill ge 17;
quit;

proc sql;
create table hcs_bup_18 as /*to be used for measures that do not require look-back*/
select unique * 
from all_records_step_f a, bup b
where a.ndc11_char = b.ndc_char and 
		a.age_at_fill ge 18;
quit;


/**************************************************************************************************************************************************/
/*Step N. From the table created in step F, use the  HCS Approved dataset with appended MME data to select all filled prescriptions for opioids. */
/*Exclude the following buprenorphine formulations: extended release subcutaneous, implant, and tablet. Exclude buprenorphine/naloxone film. */
/*Exclude solution formulations of codeine.*/
/**************************************************************************************************************************************************/

proc sql;
create table hcs_opioid_17 as
select unique *
from all_records_step_f a, opioid b
where 	a.ndc11_char = b.ndc_char and 
		a.age_at_fill ge 17;
quit;

proc sql;
create table hcs_opioid_18 as
select unique *
from all_records_step_f a, opioid b
where 	a.ndc11_char = b.ndc_char and 
		a.age_at_fill ge 18;
quit;

/**************************************************************************************************************************************************/
/*Step O.From the table created in step F, use the  HCS Approved dataset to select all filled prescriptions for benzodiazepines.*/
/**************************************************************************************************************************************************/

proc sql;
create table hcs_benzo as
select unique *
from all_records_step_f a, benzo b
where a.ndc11_char = b.ndc_char;
quit;






/********************************************************************************************************************************************/
/********************************************************************************************************************************************/
/********************************************************************************************************************************************/






/************************************************************************************************************************/
/*calculate periods of continuous treatment for opioids and buprenorphine*/
/************************************************************************************************************************/

%macro continuous(dset);


proc sql;
create table &dset._step01 as
select unique 	patient_id length = 100, 
				&start_date as date_filled format date9.,
				0 as quantity_dispensed,
				0 as days_dispensed,
				1 as filler_record
from &dset
union all
select unique 	patient_id length = 100,
				&end_date as date_filled format date9.,
				0 as quantity_dispensed,
				0 as days_dispensed,
				1 as filler_record
from &dset
;
quit;

data &dset._step02; set &dset. &dset._step01; run;

proc sort data=&dset._step02; by patient_id date_filled descending days_dispensed; run;

data &dset._step03; set &dset._step02; by patient_id date_filled descending days_dispensed;
retain patient_obs_incl_overlap;
if first.patient_id then patient_obs_incl_overlap = 1;
else patient_obs_incl_overlap = patient_obs_incl_overlap + 1;

if filler_record = 1 then date_run_out = date_filled + 0;

run;


/*Compare the fill dates and run-out dates of each prescription. */
/*If one prescription completely overlaps a prescription with a shorter duration and an earlier run-out */
/*date (fill date B = fill date A and run-out date B < run-out date A) then remove the prescription with the shorter */
/*duration.  */


proc sql;
create table &dset._step04_temp as
select 	a.patient_id length = 100,
		a.patient_obs_incl_overlap,
		a.date_filled, 
		a.days_dispensed, 
		a.date_run_out,
		pre.date_run_out as pre_date_run_out,
		1 as overlapped
from &dset._step03 a, &dset._step03 pre
where  a.patient_id = pre.patient_id and
		((a.patient_obs_incl_overlap-1) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-2) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-3) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-4) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-5) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-6) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-7) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-8) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-9) = pre.patient_obs_incl_overlap or
		 (a.patient_obs_incl_overlap-10) = pre.patient_obs_incl_overlap ) and 
	  a.filler_record ne 1 and
	  a.date_run_out < pre.date_run_out
order by a.patient_id, a.patient_obs_incl_overlap;
quit;



proc sql;
create table &dset._step04 as
select unique patient_id, patient_obs_incl_overlap
from &dset._step04_temp
where patient_id ne '';
quit;



data &dset._step05; merge &dset._step03(in=a) &dset._step04(in=b); by patient_id patient_obs_incl_overlap; 
if  b then delete; /*delete overlapped records to calculate treatment gaps*/
run;


data &dset._step06; set &dset._step05; by patient_id patient_obs_incl_overlap; 
retain patient_obs_excl_overlap;

if first.patient_id then patient_obs_excl_overlap = 1;
else patient_obs_excl_overlap = patient_obs_excl_overlap + 1;
run;

proc sql;
create table &dset._step07 as
select  a.patient_id,
		a.patient_obs_excl_overlap,
		a.date_filled, 
		a.days_dispensed, 
		a.date_run_out,
		a.filler_record,
		a.age_at_fill,	
		(b.date_filled - a.date_run_out - 1) as gap_after
from &dset._step06 a, &dset._step06 b
where a.patient_id = b.patient_id and
	  b.patient_obs_excl_overlap = (a.patient_obs_excl_overlap + 1)
order by a.patient_id, a.patient_obs_excl_overlap;
quit;

proc sql;
create table &dset._step08 as
select  a.patient_id,
		a.patient_obs_excl_overlap,
		b.gap_after as gap_prior
from &dset._step07 a, &dset._step07 b
where a.patient_id = b.patient_id and
	  b.patient_obs_excl_overlap = (a.patient_obs_excl_overlap - 1)
order by a.patient_id, a.patient_obs_excl_overlap;
quit;

data &dset._step09; merge &dset._step07 &dset._step08; by patient_id patient_obs_excl_overlap;
if filler_record = 1 then delete;
drop filler_record;
run;

data &dset._step10; set &dset._step09; by patient_id patient_obs_excl_overlap;
retain contin_period;
if first.patient_id then contin_period = 1;
if not first.patient_id and gap_prior ge 8 then contin_period = contin_period+1;
run;

proc sql;
create table &dset._step11 as
select unique 	patient_id,
				contin_period,
				min(patient_obs_excl_overlap) as min_patient_obs_excl_overlap,
				min(date_filled) as min_date_filled format date9.,
				max(date_run_out) as max_date_run_out format date9.,
				min(age_at_fill) as min_age_at_fill, /*new 20240419*/
				(max(date_run_out) - min(date_filled) + 1) as duration
from &dset._step10
group by patient_id, contin_period;
quit;

proc sql;
create table &dset._step12 as 
select a.*, 
	   b.gap_prior
from &dset._step11 a, &dset._step10 b, &dset._step06 c
where a.patient_id = b.patient_id and
	  a.patient_id = c.patient_id and
	  a.min_patient_obs_excl_overlap = b.patient_obs_excl_overlap and
	  a.min_patient_obs_excl_overlap = c.patient_obs_excl_overlap;
quit;

%mend continuous;

%continuous(hcs_bup_17);
%continuous(hcs_bup_18);
%continuous(hcs_opioid_17);
%continuous(hcs_opioid_18);






/*******************************************************************************************************/
/******************************************** Outcome 2.13 *********************************************/
/*********************************INCIDENT HIGH-RISK OPIOID PRESCRIBING*********************************/
/*******************************************************************************************************/
/*******************************************************************************************************/


/**********************************************************************************/
/*A. Risk of continued opioid use (new opioid episode lasting at least 31 days)   */
/**********************************************************************************/

/********************************/
/********* new 20200429 *********/
/********************************/

data outcome_2_13_a_step00; 
set hcs_opioid_18_step12;
year = year(min_date_filled);
quarter = qtr(min_date_filled);
month = month(min_date_filled);
where gap_prior ge 45;
run;

data outcome_2_13_a_step01;
set outcome_2_13_a_step00;
where duration ge 31;
run;

/********************************/
/********************************/
/********************************/




data outcome_2_13_a_step01; 
set hcs_opioid_18_step12;
year = year(min_date_filled);
quarter = qtr(min_date_filled);
month = month(min_date_filled);
where duration ge 31 and gap_prior ge 45;
run;


/***************************************************/
/*************** add evaluation year ***************/
/***************************************************/

proc sql;
create table outcome_2_13_a_step02_orig as
select unique	patient_id, 
				year, 
				quarter,
				month
from outcome_2_13_a_step01;
quit;



data outcome_2_13_a_step02_eval;
set  outcome_2_13_a_step02_orig;
where 	(year = 2021 and month in (7,8,9,10,11,12)) or
		(year = 2022 and month in (1,2,3,4,5,6));

year = 20212022;
drop quarter month;
run;


data outcome_2_13_a_step02;
set  outcome_2_13_a_step02_orig
	 outcome_2_13_a_step02_eval;
run;



/***************************************************/
/***************************************************/
/***************************************************/


proc sql;
create table outcome_2_13_a_step03 as 
select 	a.patient_id,
		a.year,
		a.month,
		b.community
from outcome_2_13_a_step02 a, step_j b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.month = b.month;
quit;

proc sql;
create table outcome_2_13_a_step04 as 
select 	a.patient_id,
		a.year,
		a.quarter,
		b.community
from outcome_2_13_a_step02 a, step_k b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_13_a_step05 as 
select 	a.patient_id,
		a.year,
		b.community
from outcome_2_13_a_step02 a, step_l b
where a.patient_id = b.patient_id and
	  a.year = b.year;
quit;







%macro count_months(measure, dset);
proc sql;
create table temp_&measure._counts_m as
select unique 	a.community, 
				a.year, 
				a.month,
				b.complete,
				count(unique a.patient_id) as patient_count	
from &dset a, months b
where a.year = b.year and
	  a.month = b.month	
group by a.community, a.year, a.month;
quit;

data outcome_&measure._counts_m; 
merge all_possible_m (in=x) temp_&measure._counts_m (in=y); by community year month;
if x;
if not y then patient_count = 0;
run;

%mend count_months;


%macro count_qtrs(measure, dset);
proc sql;
create table temp_&measure._counts_q as
select unique 	a.community, 
				a.year, 
				a.quarter,
				b.complete,
				count(unique a.patient_id) as patient_count	
from &dset a, quarters b
where a.year = b.year and
	  a.quarter = b.quarter	
group by a.community, a.year, a.quarter;
quit;


data outcome_&measure._counts_q; 
merge all_possible_q (in=x) temp_&measure._counts_q (in=y); by community year quarter;
if x;
if not y then patient_count = 0;
run;

%mend count_qtrs;







%macro count_years(measure, dset);


/*****************************/
/*calculate stratified counts*/
/*****************************/
proc sql;
create table strat0_&measure._counts as
select a.*, 
	   b.age_cat_for_strat,
	   b.sex_for_strat
from &dset a, strat b
where a.patient_id = b.patient_id and 
	  a.year = b.year_for_join;
quit;

proc sql;
create table strat_age_&measure._0 as
select unique 	a.community, 
				a.year,
				a.age_cat_for_strat as strat label = 'strat',
				'AGE' as strat_type,
				count(unique a.patient_id) as patient_count	
from strat0_&measure._counts a, years b
where a.year = b.year
group by a.community, a.year, a.age_cat_for_strat;
quit;

proc sql;
create table strat_sex_&measure._0 as
select unique 	a.community, 
				a.year,
				a.sex_for_strat as strat label = 'strat',
				'SEX' as strat_type,
				count(unique a.patient_id) as patient_count	
from strat0_&measure._counts a, years b
where a.year = b.year
group by a.community, a.year, a.sex_for_strat;
quit;

data strat1_&measure._counts;
length strat_type $10;
set strat_age_&measure._0
	strat_sex_&measure._0;
run; 


/*****************************************************************************************************************/
/*combinations of communiy/year with only one stratification group suppressed will require reciprocal suppression*/
/*create a flag for reciprocal suppression*/
/*****************************************************************************************************************/

proc sql;
create table supp_strat_&measure as
select unique 	strat_type,
				community,
				year,
				count(year) as strat_supp_count
from strat1_&measure._counts
where patient_count in (1,2,3,4)
group by strat_type, community, year;
quit;




/******************************/
/*zero-fill stratrified counts*/
/******************************/

proc sort data=all_possible_strat; by strat_type strat community year; run;
proc sort data=strat1_&measure._counts; by strat_type strat community year; run;

 
data strat2_&measure._counts;  
merge all_possible_strat(in=x) strat1_&measure._counts(in=y); by strat_type strat community year; 
if x;
if not y then do; 
	patient_count = 0;
end;
run;



proc sort data=strat2_&measure._counts; by strat_type community year; run;
proc sort data=supp_strat_&measure; by strat_type community year; run;


data strat3_&measure._counts;
merge strat2_&measure._counts supp_strat_&measure(in=aaa); by strat_type community year; 
if not aaa then strat_supp_count = 0;
run;

/************************/
/*reciprocal suppression*/
/************************/



proc sql;
create table strat4_&measure._counts as 
select * 
from strat3_&measure._counts
where strat_supp_count = 1;
quit;

proc sql;
create table strat5_&measure._counts as 
select unique 	community,
				year,
				strat_type,
				min(patient_count) as patient_count,
				1 as flag_smallest_nonsupp
from strat4_&measure._counts
where patient_count not in (1,2,3,4)
group by community, year, strat_type;
quit;

proc sort data=strat3_&measure._counts; by community year strat_type patient_count; run;
proc sort data=strat5_&measure._counts; by community year strat_type patient_count; run;

data strat6_&measure._counts;
merge strat3_&measure._counts strat5_&measure._counts(in=a); by community year strat_type patient_count;
if a;
run;

proc sort data=strat6_&measure._counts; by community year strat_type strat; run;

data strat7_&measure._counts;
set strat6_&measure._counts; by community year strat_type strat; 
if not first.strat_type then delete;

reciprocal_supp = 1;

keep community year strat_type strat reciprocal_supp;
run;


proc sort data=strat3_&measure._counts; by community year strat_type strat; run;
proc sort data=strat7_&measure._counts; by community year strat_type strat; run;

data strat8_&measure._counts; merge strat3_&measure._counts strat7_&measure._counts; by community year strat_type strat; run;



data strat_&measure._counts;
set strat8_&measure._counts;
if reciprocal_supp = 1 then patient_count = -88888;
drop reciprocal_supp;
run;
/***************************************************/
/***************************************************/
/***************************************************/




/************************/
/*calculate total counts*/
/************************/

proc sql;
create table temp_&measure._counts_y as
select unique 	a.community, 
				a.year, 
				b.complete,
				count(unique a.patient_id) as patient_count	
from &dset a, years b
where a.year = b.year
group by a.community, a.year;
quit;

/************************/
/*zero-fill total counts*/
/************************/

data outcome_&measure._counts_y0; 
merge all_possible_y (in=x) temp_&measure._counts_y (in=y); by community year;
if x;
if not y then patient_count = 0;
run;

data outcome_&measure._counts_y;
set outcome_&measure._counts_y0
 	strat_&measure._counts;
run;

%mend count_years;



%count_months(2_13_a, outcome_2_13_a_step03);
%count_qtrs(2_13_a, outcome_2_13_a_step04);
%count_years(2_13_a, outcome_2_13_a_step05);









/***********************************************************/
/***********************************************************/
/***********************************************************/



/**********************************************************************************************/
/**********************************************************************************************/
/**********************************************************************************************/
/**********************************************************************************************/
/**********************************************************************************************/
/**********************************************************************************************/
/**********************************************************************************************/


/**********************************************************************************/
/*B. Initiating opioid treatment with Extended-release or Long-acting opioid      */
/**********************************************************************************/





/***************************************************************************************************************/
/*Correction 20200428. Was previously using outcome_2_13_a_step01, which is limited to episodes lasting 31 days*/
/********************************Now using the new outcome_2_13_a_step00****************************************/
/***************************************************************************************************************/


/*possibly creating multiple records if two opioid prescriptions filled on one day but select unique in next step*/
proc sql;
create table outcome_2_13_b_step01
as select a.*, b.long_act  
from outcome_2_13_a_step00 a,
	 hcs_opioid_18 b
where 	a.patient_id = b.patient_id and
		a.min_date_filled = b.date_filled and
		b.long_act = 1;
quit;




/***************************************************************************************************************/
/***************************************************************************************************************/
/***************************************************************************************************************/



/***************************************************/
/*************** add evaluation year ***************/
/***************************************************/

proc sql;
create table outcome_2_13_b_step02_orig as
select unique	patient_id, 
				year, 
				quarter,
				month
from outcome_2_13_b_step01;
quit;



data outcome_2_13_b_step02_eval;
set  outcome_2_13_b_step02_orig;
where 	(year = 2021 and month in (7,8,9,10,11,12)) or
		(year = 2022 and month in (1,2,3,4,5,6));

year = 20212022;
drop quarter month;
run;


data outcome_2_13_b_step02;
set  outcome_2_13_b_step02_orig
	 outcome_2_13_b_step02_eval;
run;



/***************************************************/
/***************************************************/
/***************************************************/




proc sql;
create table outcome_2_13_b_step03 as 
select unique 	a.patient_id,
				a.year,
				a.month,
				b.community
from outcome_2_13_b_step02 a, step_j b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.month = b.month;
quit;

proc sql;
create table outcome_2_13_b_step04 as 
select unique 	a.patient_id,
				a.year,
				a.quarter,
				b.community
from outcome_2_13_b_step02 a, step_k b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_13_b_step05 as 
select unique 	a.patient_id,
				a.year,
				b.community
from outcome_2_13_b_step02 a, step_l b
where a.patient_id = b.patient_id and
	  a.year = b.year;
quit;

%count_months(2_13_b, outcome_2_13_b_step03);
%count_qtrs(2_13_b, outcome_2_13_b_step04);
%count_years(2_13_b, outcome_2_13_b_step05);


/**********************************************************************************/
/*C. Incident High dosage (average > 90 mg morphine per day)                   */
/**********************************************************************************/

data outcome_2_13_c_step01; 
set hcs_opioid_17;
where mme_conversion_factor ne .;
keep patient_id date_filled days_dispensed strength_per_unit quantity_dispensed mme_conversion_factor date_run_out;
run;

data outcome_2_13_c_step02;
set outcome_2_13_c_step01;
mme_per_day = strength_per_unit*mme_conversion_factor*(quantity_dispensed/days_dispensed);
run;

/*CREATING A NULL ROW*/
proc sql;
create table outcome_2_13_c_step03 as
select unique 	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" as patient_id length = 100,
				mdy(01,01,2000) as date format date9.,
				2000 as year,
				1 as month,
				sum(mme_per_day) as mme
from outcome_2_13_c_step02
where date_filled le mdy(01,01,2000) le date_run_out;
quit;

/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/****************THIS IS THE STEP THAT WAS DISCUSSED ON THE MARCH 12, 2020 WEEKLY DATA CAPTURE LEADERSHIP WG CALL*****************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/

%macro mme_per_day(date);

proc sql noprint;
insert into outcome_2_13_c_step03
select unique 	patient_id,
				&date as date format date9.,
				year(&date) as year,
				month(&date) as month,
				sum(mme_per_day) as mme
from outcome_2_13_c_step02
where date_filled le &date le date_run_out
group by patient_id
;
quit;

%mend mme_per_day;





/*NEW 20200501 to suppress notes in the log*/
options nomprint nosymbolgen nonotes nosource;
/*******************************************/

data _null_; 
set date_range;
call execute('%mme_per_day('||date||')');
run;

options notes source;



/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/



proc sql;
create table outcome_2_13_c_step04 as
select unique 	patient_id,
				year,
				month,
				sum(mme) as mme_month_total
from outcome_2_13_c_step03
where year ne 2000
group by patient_id, year, month;
quit;


proc sql;
create table outcome_2_13_c_step05 as 
select unique 	a.patient_id, 
				b.year, 
				b.month,
				b.days
from outcome_2_13_c_step04 a, months b
where b.complete = 1
order by 	a.patient_id,
			b.year,
			b.month;
quit;


data outcome_2_13_c_step06; merge outcome_2_13_c_step05 outcome_2_13_c_step04 (in=b); by patient_id year month; 
if not b then mme_month_total = 0;
run;

proc sort data=outcome_2_13_c_step06; by patient_id year month; run;





data outcome_2_13_c_step07; set outcome_2_13_c_step06; by patient_id year month;
retain obs;
if first.patient_id then obs = 1;
else obs = obs+1;
run;

proc sql;
create table outcome_2_13_c_step08 as
select 	a.*, 
		sum(a.mme_month_total, b.mme_month_total, c.mme_month_total) as moving_sum format 9.2,
		sum(a.days, b.days, c.days) as days_in_moving_quarter
from outcome_2_13_c_step07 a, outcome_2_13_c_step07 b, outcome_2_13_c_step07 c
where 	a.patient_id = b.patient_id and
		b.patient_id = c.patient_id and 
		b.obs = (a.obs - 1) and
		c.obs = (b.obs - 1);
quit;

data outcome_2_13_c_step09; set outcome_2_13_c_step08;
	mean_daily_dosage = moving_sum/days_in_moving_quarter;
	if mean_daily_dosage ge 90 then interim_flag_1 = 1;
	if 0 le mean_daily_dosage lt 90 then interim_flag_1 = 0;
format mean_daily_dosage 8.2;
run;


proc sql;
create table outcome_2_13_c_step10 as 
select a.*, b.interim_flag_1 as interim_flag_2
from outcome_2_13_c_step09 a, outcome_2_13_c_step09 b
where a.patient_id = b.patient_id and 
	 b.obs = (a.obs-3);
quit;

%macro compare_flags();
if interim_flag_1 = . or interim_flag_2 = . then measure_flag = .;
if interim_flag_1 in (0,1) and interim_flag_2 = 1 then measure_flag = 0;
if interim_flag_1 = 1 and interim_flag_2 = 0 then measure_flag = 1;
if interim_flag_1 = 0 and interim_flag_2 = 0 then measure_flag = 0;
%mend compare_flags;

data outcome_2_13_c_step11; set outcome_2_13_c_step10;
%compare_flags();
run;


proc sql;
create table outcome_2_13_c_step12 as
select 	a.*,
		b.year_18yo, 
		b.month_dob
from outcome_2_13_c_step11 a, pmp_dobs b 
where 	a.patient_id = b.patient_id and
		(a.year ge b.year_18yo or (a.year eq b.year_18yo and a.month ge b.month_dob));
quit;


proc sql; 
create table outcome_2_13_c_step13_orig as 
select unique patient_id, year, month
from outcome_2_13_c_step12
where measure_flag = 1;
quit;



/***************************************************/
/*************** add evaluation year ***************/
/***************************************************/



data outcome_2_13_c_step13_eval;
set  outcome_2_13_c_step13_orig;
where 	(year = 2021 and month in (7,8,9,10,11,12)) or
		(year = 2022 and month in (1,2,3,4,5,6));

year = 20212022;
run;


data outcome_2_13_c_step13;
set  outcome_2_13_c_step13_orig
	 outcome_2_13_c_step13_eval;
run;
/***************************************************/
/***************************************************/
/***************************************************/



/*modified in version 13*/
/*From the table created in C30, flag calendar */
/*quarters that include one or more months where 2.13C flag = 1.*/

data outcome_2_13_c_step14; 
set outcome_2_13_c_step13;
if month in (1,2,3) then quarter = 1;
if month in (4,5,6) then quarter = 2;
if month in (7,8,9) then quarter = 3;
if month in (10,11,12) then quarter = 4;
run;

proc sql;
create table outcome_2_13_c_step15 as
select unique 	patient_id, 
				year, 
				quarter
from outcome_2_13_c_step14
where quarter ne .;
quit;


proc sql;
create table outcome_2_13_c_step16 as
select unique 	patient_id, 
				year
from outcome_2_13_c_step15;
quit;


proc sql;
create table outcome_2_13_c_step17 as 
select 	a.patient_id,
		a.year,
		a.month,
		b.community
from outcome_2_13_c_step13 a, step_j b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.month = b.month;
quit;

proc sql;
create table outcome_2_13_c_step18 as 
select 	a.patient_id,
		a.year,
		a.quarter,
		b.community
from outcome_2_13_c_step15 a, step_k b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_13_c_step19 as 
select 	a.patient_id,
		a.year,
		b.community
from outcome_2_13_c_step16 a, step_l b
where a.patient_id = b.patient_id and
	  a.year = b.year;
quit;


%count_months(2_13_c, outcome_2_13_c_step17);
%count_qtrs(2_13_c, outcome_2_13_c_step18);
%count_years(2_13_c, outcome_2_13_c_step19);








/***********************************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/



/**********************************************************************************/
/*D. Incident Overlapping opioid and benzodiazepine for at least 31 days       */
/**********************************************************************************/


data outcome_2_13_d_step01; 
set hcs_benzo;
keep patient_id date_filled days_dispensed quantity_dispensed date_run_out;
run;


/*CREATING A NULL ROW*/
proc sql;
create table outcome_2_13_d_step02 as
select unique 	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" as patient_id length = 100, 
				mdy(01,01,2000) as date format date9.,
				1 as benzo
from outcome_2_13_d_step01
where date_filled le mdy(01,01,2000) le date_run_out;
quit;



%macro benzo_per_day(date);

proc sql noprint;
reset noprint;
insert into outcome_2_13_d_step02
select unique 	patient_id, 
				&date as date format date9.,
				1 as benzo
from outcome_2_13_d_step01
where date_filled le &date le date_run_out;
quit;

%mend benzo_per_day;

/*NEW 20200501 to suppress notes in the log*/
options nomprint nosymbolgen nonotes nosource ;
/*******************************************/
data _null_; 
set date_range;
call execute('%benzo_per_day('||date||')');
run;
options notes source;


proc sort data=outcome_2_13_d_step02; by patient_id date; run;
proc sort data=outcome_2_13_c_step03; by patient_id date; run;


data outcome_2_13_d_step03;
merge outcome_2_13_d_step02 (in=a) outcome_2_13_c_step03(in=b); by patient_id date; 
if a and b;
run; 


proc sql;
create table outcome_2_13_d_step04 as
select unique 	patient_id,
				year,
				month,
				count(patient_id) as days_of_overlap
from outcome_2_13_d_step03
where year ne 2000
group by patient_id, year, month;
quit;

proc sql;
create table outcome_2_13_d_step05 as 
select unique 	a.patient_id, 
				b.year, 
				b.month
from outcome_2_13_d_step04 a, months b
where b.complete = 1
order by 	a.patient_id,
			b.year,
			b.month;
quit;

data outcome_2_13_d_step06; merge outcome_2_13_d_step05 outcome_2_13_d_step04 (in=b); by patient_id year month; 
if not b then days_of_overlap = 0;
run;

data outcome_2_13_d_step07; set outcome_2_13_d_step06; by patient_id year month;
retain obs;
if first.patient_id then obs = 1;
else obs = obs+1;
run;

proc sql;
create table outcome_2_13_d_step08 as
select 	a.*, 
		sum(a.days_of_overlap, b.days_of_overlap, c.days_of_overlap) as moving_sum
from outcome_2_13_d_step07 a, outcome_2_13_d_step07 b, outcome_2_13_d_step07 c
where 	a.patient_id = b.patient_id and
		b.patient_id = c.patient_id and 
		b.obs = (a.obs - 1) and
		c.obs = (b.obs - 1);
quit;

data outcome_2_13_d_step09; set outcome_2_13_d_step08;
	if moving_sum ge 31 then interim_flag_1 = 1;
	if 0 le moving_sum lt 31 then interim_flag_1 = 0;
run;

proc sql;
create table outcome_2_13_d_step10 as 
select a.*, b.interim_flag_1 as interim_flag_2
from outcome_2_13_d_step09 a, outcome_2_13_d_step09 b
where a.patient_id = b.patient_id and 
	 b.obs = (a.obs-3);
quit;

data outcome_2_13_d_step11; set outcome_2_13_d_step10;
%compare_flags();
run;


proc sql;
create table outcome_2_13_d_step12 as
select 	a.*,
		b.year_18yo, 
		b.month_dob
from outcome_2_13_d_step11 a, pmp_dobs b 
where 	a.patient_id = b.patient_id and
		(a.year ge b.year_18yo or (a.year eq b.year_18yo and a.month ge b.month_dob));
quit;

proc sql; 
create table outcome_2_13_d_step13_orig as 
select unique patient_id, year, month
from outcome_2_13_d_step12
where measure_flag = 1;
quit;




/***************************************************/
/*************** add evaluation year ***************/
/***************************************************/



data outcome_2_13_d_step13_eval;
set  outcome_2_13_d_step13_orig;
where 	(year = 2021 and month in (7,8,9,10,11,12)) or
		(year = 2022 and month in (1,2,3,4,5,6));

year = 20212022;
run;


data outcome_2_13_d_step13;
set  outcome_2_13_d_step13_orig
	 outcome_2_13_d_step13_eval;
run;
/***************************************************/
/***************************************************/
/***************************************************/






/*new in version 13*/
/*From the table created in D43, flag calendar quarters */
/*that include one or more months*/
/*where 2.13D flag = 1.*/

data outcome_2_13_d_step14;
set outcome_2_13_d_step13;
if month in (1,2,3) then quarter = 1;
if month in (4,5,6) then quarter = 2;
if month in (7,8,9) then quarter = 3;
if month in (10,11,12) then quarter = 4;
run;

proc sql;
create table outcome_2_13_d_step15 as
select unique 	patient_id, 
				year, 
				quarter
from outcome_2_13_d_step14
where quarter ne .;
quit;

proc sql;
create table outcome_2_13_d_step16 as
select unique 	patient_id, 
				year
from outcome_2_13_d_step15;
quit;


proc sql;
create table outcome_2_13_d_step17 as 
select unique 	a.patient_id,
				a.year,
				a.month,
				b.community
from outcome_2_13_d_step13 a, step_j b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.month = b.month;
quit;

proc sql;
create table outcome_2_13_d_step18 as 
select unique  	a.patient_id,
				a.year,
				a.quarter,
				b.community
from outcome_2_13_d_step15 a, step_k b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_13_d_step19 as 
select unique  	a.patient_id,
				a.year,
				b.community
from outcome_2_13_d_step16 a, step_l b
where a.patient_id = b.patient_id and
	  a.year = b.year;
quit;


%count_months(2_13_d, outcome_2_13_d_step17);
%count_qtrs(2_13_d, outcome_2_13_d_step18);
%count_years(2_13_d, outcome_2_13_d_step19);






/**********************************************************************************/
/*Outcome 2.13 combined    */
/**********************************************************************************/


data outcome_2_13_all_m;
length patient_id $100;
set outcome_2_13_a_step03 (in=a)
	outcome_2_13_b_step03 (in=b)
	outcome_2_13_c_step17 (in=c)
	outcome_2_13_d_step17 (in=d);

if a then outcome = 'A';
if b then outcome = 'B';
if c then outcome = 'C';
if d then outcome = 'D';

run;

proc sql;
create table outcome_2_13_all_m_unique as
select unique 	patient_id, 
				community, 
				year, 
				month
from outcome_2_13_all_m;
quit;



data outcome_2_13_all_q;
length patient_id $100;
set outcome_2_13_a_step04 (in=a)
	outcome_2_13_b_step04 (in=b)
	outcome_2_13_c_step18 (in=c)
	outcome_2_13_d_step18 (in=d);

if a then outcome = 'A';
if b then outcome = 'B';
if c then outcome = 'C';
if d then outcome = 'D';

run;

proc sql;
create table outcome_2_13_all_q_unique as
select unique 	patient_id, 
				community, 
				year, 
				quarter
from outcome_2_13_all_q;
quit;



data outcome_2_13_all_y;
length patient_id $100;
set outcome_2_13_a_step05 (in=a)
	outcome_2_13_b_step05 (in=b)
	outcome_2_13_c_step19 (in=c)
	outcome_2_13_d_step19 (in=d);

if a then outcome = 'A';
if b then outcome = 'B';
if c then outcome = 'C';
if d then outcome = 'D';

run;

proc sql;
create table outcome_2_13_all_y_unique as
select unique 	patient_id, 
				community, 
				year
from outcome_2_13_all_y;
quit;


%count_months(2_13_all, outcome_2_13_all_m_unique);
%count_qtrs(2_13_all, outcome_2_13_all_q_unique);
%count_years(2_13_all, outcome_2_13_all_y_unique);



/****************************************************************************************************/
/******************************************* Outcome 2.5.1 ******************************************/
/*NUMBER OF INDIVIDUALS RECEIVING BUPRENORPHINE PRODUCTS THAT ARE FDA-APPROVED FOR TREATMENT OF OUD*/
/****************************************************************************************************/
/****************************************************************************************************/


proc sql;
create table outcome_2_5_1_step01_orig as
select unique 	patient_id,
				year_filled as year,
				quarter_filled as quarter,	
			  	month_filled as month
from hcs_bup_18;
quit;

/**********************************************/
/*****************new 20221007*****************/
/********create "study years" for 2.5.1********/
/**********************************************/

%macro sy251(ymin,ymax);

data outcome_2_5_1_step01_&ymin.&ymax;
set outcome_2_5_1_step01_orig;
where 	(year = &ymin and month in (7,8,9,10,11,12)) or
		(year = &ymax and month in (1,2,3,4,5,6));

year = &ymin.&ymax;
drop quarter month;
run;

%mend sy251;

%sy251(2017,2018);
%sy251(2018,2019);
%sy251(2019,2020);
%sy251(2020,2021);
%sy251(2021,2022);
%sy251(2022,2023);



data outcome_2_5_1_step01;
set outcome_2_5_1_step01_orig
	outcome_2_5_1_step01_20:;
run;


proc sql;
create table outcome_2_5_1_step02 as
select unique a.patient_id, a.year, a.month, b.community
from outcome_2_5_1_step01 a, step_j b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.month = b.month;
quit;

proc sql;
create table outcome_2_5_1_step03 as
select unique a.patient_id, a.year, a.quarter, b.community
from outcome_2_5_1_step01 a, step_k b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_5_1_step04 as
select unique a.patient_id, a.year, b.community
from outcome_2_5_1_step01 a, step_l b
where 	a.patient_id = b.patient_id and
		a.year = b.year;
quit;



%count_months(2_5_1, outcome_2_5_1_step02);
%count_qtrs(2_5_1, outcome_2_5_1_step03);
%count_years(2_5_1, outcome_2_5_1_step04);


/****************************************************************************************************/
/****************************************************************************************************/
/****************************************************************************************************/
/****************************************************************************************************/
/****************************************************************************************************/




/*******************************************************************************************/
/************************************** Outcome 2.7.1 **************************************/
/******NUMBER OF INDIVIDUALS RECEIVING BUPRENORPHINE/NALOXONE RETAINED BEYOND 6 MONTHS******/
/*******************************************************************************************/
/*******************************************************************************************/



data outcome_2_7_1_step01;
set hcs_bup_17_step12;
threshold_date = min_date_filled + 179; /*new 20240419*/
format threshold_date date9.;
where duration ge 180;
run;

/*CREATING A NULL ROW*/
proc sql;
create table outcome_2_7_1_step02 as
select unique 	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" as patient_id length = 100, 
				0 as year,
				0 as quarter,
				0 as month
from first_and_last;
quit;



%macro retained_6mo2(start, end); /*new 20240419*/

proc sql noprint;
insert into outcome_2_7_1_step02
select unique 	patient_id,
				year(&start) as year,
				qtr(&start) as quarter,
				month(&start) as month
from outcome_2_7_1_step01
where max_date_run_out ge &start 
	and threshold_date le &end;
quit;

%mend retained_6mo2;


/*NEW 20200501 to suppress notes in the log*/
options nomprint nosymbolgen nonotes nosource;
/*******************************************/
data _null_; 
set month_start_end;
call execute('%retained_6mo2('||start||','||end||')');/*new 20240419*/
run;
options notes source;





proc sql;
create table outcome_2_7_1_step03 as
select unique * 
from outcome_2_7_1_step02
where year ne 0;
quit;

proc sql;
create table outcome_2_7_1_step04 as 
select unique a.*,
			  b.year_18yo,
			  b.month_dob
from outcome_2_7_1_step03 a, pmp_dobs b
where a.patient_id = b.patient_id;
quit;

/*new 20220623*/
data outcome_2_7_1_step05_orig; 
set outcome_2_7_1_step04;
if year lt year_18yo then delete;
if year eq year_18yo and month lt month_dob then delete;
run; 

data outcome_2_7_1_step05_eval;
set outcome_2_7_1_step05_orig;
where 	(year = 2021 and month in (7,8,9,10,11,12)) or
		(year = 2022 and month in (1,2,3,4,5,6));

year = 20212022;
drop quarter month;
run;

data outcome_2_7_1_step05;
set outcome_2_7_1_step05_orig
	outcome_2_7_1_step05_eval;
run;
/**************/



proc sql;
create table outcome_2_7_1_step06 as 
select unique	a.patient_id,
				a.year,
				a.month,
				b.community
from outcome_2_7_1_step05 a, step_j b
where 	a.patient_id = b.patient_id and 
		a.year = b.year and
		a.month = b.month;
quit;

proc sql;
create table outcome_2_7_1_step07 as 
select unique 	a.patient_id,
				a.year,
				a.quarter,
				b.community
from outcome_2_7_1_step05 a, step_k b
where 	a.patient_id = b.patient_id and
		a.year = b.year and
		a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_7_1_step08 as 
select unique 	a.patient_id,
				a.year,
				b.community
from outcome_2_7_1_step05 a, step_l b
where 	a.patient_id = b.patient_id and
		a.year = b.year;
quit;




%count_months(2_7_1, outcome_2_7_1_step06);
%count_qtrs(2_7_1, outcome_2_7_1_step07);
%count_years(2_7_1, outcome_2_7_1_step08);



/**************************************************************************************/
/************************************ Outcome 2.18 ************************************/
/***************NEW ACUTE OPIOID PRESCRIPTIONS LIMITED TO A 7 DAY SUPPLY***************/
/**************************************************************************************/
/**************************************************************************************/


data outcome_2_18_denom_step01; 
set hcs_opioid_17_step12; /*new 20240419*/ 
year = year(min_date_filled);
quarter = qtr(min_date_filled);
month = month(min_date_filled);
where gap_prior ge 45 and
		min_age_at_fill ge 18;/*new 20240419*/ 
run;


proc sql;
create table outcome_2_18_denom_step02 as
select unique 	patient_id, 
				year, 
				quarter, 
				month
from outcome_2_18_denom_step01;
quit;


proc sql;
create table outcome_2_18_denom_step03 as
select unique a.*, b.community
from outcome_2_18_denom_step02 a, step_j b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.month = b.month;
quit;

proc sql;
create table outcome_2_18_denom_step04 as
select unique a.*, b.community
from outcome_2_18_denom_step02 a, step_k b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.quarter = b.quarter;
quit;

/*******************************************************/
/***************** add evaluation year *****************/
/*******************************************************/


data outcome_2_18_denom_step05_eval;
set outcome_2_18_denom_step02; /*new 20240419*/
where 	(year = 2021 and month in (7,8,9,10,11,12)) or
		(year = 2022 and month in (1,2,3,4,5,6));
year = 20212022;
drop quarter month;
run;


data outcome_2_18_denom_step05_all;
set outcome_2_18_denom_step02 /*new 20240419*/
	outcome_2_18_denom_step05_eval;
run;


proc sql;/*new 20240419*/
create table outcome_2_18_denom_step05 as
select unique a.*, b.community
from outcome_2_18_denom_step05_all a, step_l b
where 	a.patient_id = b.patient_id and
		a.year = b.year;
quit;



/*******************************************************/
/*******************************************************/
/*******************************************************/



%count_months(2_18_denom, outcome_2_18_denom_step03);
%count_qtrs(2_18_denom, outcome_2_18_denom_step04);
%count_years(2_18_denom, outcome_2_18_denom_step05);




data outcome_2_18_numer_step01; 
set hcs_opioid_17_step12;/*new 20240419*/ 
year = year(min_date_filled);
quarter = qtr(min_date_filled);
month = month(min_date_filled);
where gap_prior ge 45 and
		min_age_at_fill ge 18;/*new 20240419*/ 
run;

proc sql;
create table outcome_2_18_numer_step02 as 
select unique 	patient_id,
				year,
				quarter,
				month
from outcome_2_18_numer_step01
order by patient_id, year, quarter, month; 
quit;


/*it's possible that there are mulitple fills on the first day. find any where days dispensed are >7*/
/*do not sum across records. instead, query individual records*/
proc sql;
create table outcome_2_18_numer_step03 as
select unique 	a.patient_id,
				a.date_filled,
				a.year_filled as year,
				a.quarter_filled as quarter,
				a.month_filled as month,
				a.days_dispensed 
from hcs_opioid_17 a, outcome_2_18_numer_step01 b /*new 20240419*/
where 	a.patient_id = b.patient_id and
		a.date_filled = b.min_date_filled and
		a.days_dispensed > 7;
quit;

proc sql;
create table outcome_2_18_numer_step04 as 
select unique 	patient_id,
				year,
				quarter,
				month
from outcome_2_18_numer_step03
order by patient_id, year, quarter, month;
quit;

/*step 02 all, step04 is start dates with a >7. step05 is start dates in step02 without being in step04*/
/*because step 1 has the age filter, don't need it again*/
data outcome_2_18_numer_step05; merge outcome_2_18_numer_step02(in=a) outcome_2_18_numer_step04(in=b); by patient_id year quarter month; if a and not b; run;



/*******************************************************/
/***************** add evaluation year *****************/
/*******************************************************/

data outcome_2_18_numer_step05_orig;
set outcome_2_18_numer_step05;
run;

data outcome_2_18_numer_step05_eval;
set outcome_2_18_numer_step05;
where 	(year = 2021 and month in (7,8,9,10,11,12)) or
		(year = 2022 and month in (1,2,3,4,5,6));

year = 20212022;
drop quarter month;
run;

data outcome_2_18_numer_step05;
set outcome_2_18_numer_step05_orig
	outcome_2_18_numer_step05_eval;
run;


/*******************************************************/
/*******************************************************/
/*******************************************************/


proc sql;
create table outcome_2_18_numer_step06 as
select unique a.*, b.community
from outcome_2_18_numer_step05 a, step_j b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.month = b.month;
quit;

proc sql;
create table outcome_2_18_numer_step07 as
select unique a.*, b.community
from outcome_2_18_numer_step05 a, step_k b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.quarter = b.quarter;
quit;

proc sql;
create table outcome_2_18_numer_step08 as
select unique a.*, b.community
from outcome_2_18_numer_step05 a, step_l b
where 	a.patient_id = b.patient_id and
		a.year = b.year;
quit;


%count_months(2_18_numer, outcome_2_18_numer_step06);
%count_qtrs(2_18_numer, outcome_2_18_numer_step07);
%count_years(2_18_numer, outcome_2_18_numer_step08);


/******************************************************************************************/
/************************************** Measure 3.1 ***************************************/
/***************OPIOID PRESCRIPTIONS FROM MULTIPLE PRESCRIBERS OR PHARMACIES***************/
/******************************************************************************************/
/******************************************************************************************/

proc sql;
create table outcome_3_1_step01 as
select unique 	patient_id, 
				date_filled,
				dea_prescriber, 
				dea_pharmacy
from hcs_opioid_17;
quit;


/*2.Using the start date and end date defined in step A on page 1, create a table that includes the start date and end date of each moving quarter.*/

proc sql;
create table outcome_3_1_step02 as
select 	a.year,
		a.month,
		min(b.date) as month_start format date9.,
		max(b.date) as month_end format date9.
from months a, date_range b
where a.complete = 1 and a.month = month(b.date) and a.year = year(b.date)
group by a.year, a.month;
quit;


proc sql;
create table outcome_3_1_step03 as 
select 	b.year as year_mov_quarter_end,
		b.month as month_mov_quarter_end,
		a.month_start as mov_quarter_start format date9.,
		b.month_end as mov_quarter_end format date9.
from outcome_3_1_step02 a, outcome_3_1_step02 b
where 80 le (b.month_end - a.month_start) le 100;
quit;

proc sql;
create table outcome_3_1_step04 as 
select unique	b.patient_id,
				count(unique b.dea_prescriber) as prescriber_count,
				count(unique b.dea_pharmacy) as pharmacy_count,
				a.*
from outcome_3_1_step03 a, outcome_3_1_step01 b
where 	b.date_filled ge a.mov_quarter_start and
		b.date_filled le a.mov_quarter_end
group by b.patient_id, a.year_mov_quarter_end, a.month_mov_quarter_end;
quit;

data outcome_3_1_step05;
set outcome_3_1_step04;
if prescriber_count ge 4 or pharmacy_count ge 4 then measure_flag = 1;
if prescriber_count lt 4 and pharmacy_count lt 4 then measure_flag = 0;
run;


proc sql;
create table outcome_3_1_step06 as
select 	a.*,
		b.year_18yo, 
		b.month_dob
from outcome_3_1_step05 a, pmp_dobs b 
where 	a.patient_id = b.patient_id and
		(a.year_mov_quarter_end ge b.year_18yo or (a.year_mov_quarter_end eq b.year_18yo and a.month_mov_quarter_end ge b.month_dob));
quit;

proc sql; 
create table outcome_3_1_step07 as 
select unique 	patient_id, 
				year_mov_quarter_end as year, 
				month_mov_quarter_end as month
from outcome_3_1_step06
where measure_flag = 1;
quit;


/*new in version 13*/
/*From the table created in step 6, */
/*flag calendar quarters that include one or more*/
/*months where the 3.1 flag = 1.*/

data outcome_3_1_step08;
set outcome_3_1_step07;
if month in (1,2,3) then quarter = 1;
if month in (4,5,6) then quarter = 2;
if month in (7,8,9) then quarter = 3;
if month in (10,11,12) then quarter = 4;
run;

/*******************************************/
/************ADD EVALUATION YEAR************/
/*******************************************/

proc sql;
create table outcome_3_1_step09_orig as
select unique 	patient_id, 
				year, 
				quarter
from outcome_3_1_step08
where quarter ne .;
quit;

data outcome_3_1_step09_eval;
set outcome_3_1_step08;
where 	(year = 2021 and month in (7,8,9,10,11,12)) or
		(year = 2022 and month in (1,2,3,4,5,6));

year = 20212022;
drop quarter month;
run;

data outcome_3_1_step09;
set outcome_3_1_step09_orig
	outcome_3_1_step09_eval;
run;


/*******************************************/
/*******************************************/
/*******************************************/


proc sql;
create table outcome_3_1_step10 as
select unique 	patient_id, 
				year
from outcome_3_1_step09;
quit;


proc sql;
create table outcome_3_1_step11 as 
select unique 	a.patient_id,
				a.year,
				a.month,
				b.community
from outcome_3_1_step07 a, step_j b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.month = b.month;
quit;

proc sql;
create table outcome_3_1_step12 as 
select unique  	a.patient_id,
				a.year,
				a.quarter,
				b.community
from outcome_3_1_step09 a, step_k b
where a.patient_id = b.patient_id and
	  a.year = b.year and
	  a.quarter = b.quarter;
quit;

proc sql;
create table outcome_3_1_step13 as 
select unique	a.patient_id,
				a.year,
				b.community
from outcome_3_1_step10 a, step_l b
where a.patient_id = b.patient_id and
	  a.year = b.year;
quit;

%count_months(3_1, outcome_3_1_step11);
%count_qtrs(3_1, outcome_3_1_step12);
%count_years(3_1, outcome_3_1_step13);




/**************************************************************************************************************/
/************************************************ Measure 3.3 *************************************************/
/***************NUMBER OF PROVIDERS WITH A DATA 2000 WAIVER WHO ACTIVELY PRESCRIBE BUPRENORPHINE***************/
/**************************************************************************************************************/
/**************************************************************************************************************/

/*Step 1 is importing the DEA data*/

/*2) Create a new variable that is a substring of the DEA number that excludes the first character. Drop the full DEA number*/

data outcome_3_3_step2; set dea0;
substr_dea_number = substr(dea_reg_num, 2,8);
drop dea_reg_num;
run;


/*3) From the table of buprenorphine prescriptions from the PDMP dataset created in step M above, */
/*select all unique combinations of year written, month written, and the prescriber�s DEA number.*/

/*proc sql;*/
/*create table outcome_3_3_step3_orig as*/
/*select unique 	year_written, */
/*				month_written, */
/*				dea_prescriber*/
/*from hcs_bup_18;*/
/*quit;*/


/*new 20220906 -- select bup records from all PMP*/

/*proc sql;*/
/*create table outcome_3_3_step3 as*/
/*select unique 	year(a.dspDateWritten) as year_written, */
/*				month(a.dspDateWritten) as month_written, */
/*				a.predea as dea_prescriber*/
/*from pmp_all a, bup b*/
/*where 	a.dspDateWritten ne . and*/
/*		a.dspNDC = b.ndc_char;*/
/*quit;*/


/*new 20240419 - restrict to patients 18+*/
proc sql; 
create table outcome_3_3_step3_new as
select unique 	year(a.dspDateWritten) as year_written, 
				month(a.dspDateWritten) as month_written, 
				a.predea as dea_prescriber
from pmp_all a, bup b
where 	a.dspDateWritten ne . and
		a.dspNDC = b.ndc_char and 
		floor((intck('month',a.patBirthDate,a.dspDateWritten) - (day(a.dspDateWritten) < day(a.patBirthDate)))/12) ge 18 ;
quit;


/*proc print data=outcome_3_3_step3 noobs; run;*/
/*proc print data=outcome_3_3_step3_new noobs; run;*/



/****************************************************/
/****************************************************/
/****************************************************/
/****************************************************/



/*4) Create a new variable in the table created in step 3 that is the substring of the prescribers� DEA number */
/*that excludes the first character. Drop the variable with the full DEA number.*/


data outcome_3_3_step4; 
set outcome_3_3_step3_new;/*new 20240419*/
substr_dea_number = substr(dea_prescriber, 2,8);
drop dea_prescriber;
run;


/*5)select unique records from the table created in step 4*/
proc sql;
create table outcome_3_3_step5 as 
select unique *
from outcome_3_3_step4;
quit;



/****************************************************/
/********************new 20220701********************/
/***************create evaluation year***************/
/****************************************************/
/*6) Join the table from step 2 and step 5 on year, month, and the substring of the prescriber�s DEA number. Keep only the records that match.*/

proc sql;
create table outcome_3_3_step6_orig as
select unique a.*
from outcome_3_3_step2 a, outcome_3_3_step5 b
where 	a.year = b.year_written and 
		a.month = b.month_written and
		a.substr_dea_number = b.substr_dea_number;
quit;

data outcome_3_3_step6_eval;
set outcome_3_3_step6_orig;
where 	(year = 2021 and month in (7,8,9,10,11,12)) or
		(year = 2022 and month in (1,2,3,4,5,6));

year = 20212022;
run;

data outcome_3_3_step6;
set outcome_3_3_step6_orig
	outcome_3_3_step6_eval;
run;
/****************************************************/
/****************************************************/
/****************************************************/


/*7) From the table created in step 6, select unique Substr_DEA_number, year, quarter, and each provider�s maximum prescriber level in each quarter.*/
proc sql;
create table outcome_3_3_step7 as
select unique	substr_dea_number,
				year, 
				quarter, 
				community, 
				max(waiver_type) as max_level
from outcome_3_3_step6
group by substr_dea_number, 
		 year, 
		 quarter;
quit; 

/*8) From the table created in step 6, select unique Substr_DEA_number, year, and each provider�s maximum prescriber level in each year.*/
proc sql;
create table outcome_3_3_step8 as
select unique	substr_dea_number,
				year, 
				community, 
				max(waiver_type) as max_level
from outcome_3_3_step6
group by substr_dea_number, 
		 year;
quit; 


/*9)From the table created in step 6, count unique Substr_DEA_number, group by community, year, and  month. This is the monthly count for measure 3.3.*/
proc sql;
create table temp_outcome_3_3_counts_m as 
select unique 	count(unique substr_dea_number) as provider_count, 
				community,
				year, 
				month
from outcome_3_3_step6
group by community, year, month;
quit;

/*10)	From the table created in step 7, count unique Substr_DEA_number, group by community, year, and  quarter. This is the quarterly count for measure 3.3.*/
proc sql;
create table temp_outcome_3_3_counts_q as 
select unique 	count(unique substr_dea_number) as provider_count, 
				community,
				year, 
				quarter
from outcome_3_3_step7
group by community, year, quarter;
quit;

/*11)	From the table created in step 8, count unique Substr_DEA_number, group by community and year. This is the annual count for measure 3.3.*/
proc sql;
create table temp_outcome_3_3_counts_y as 
select unique 	count(unique substr_dea_number) as provider_count, 
				community,
				year
from outcome_3_3_step8
group by community, year;
quit;


/*12) From the table created in step 6, count unique Substr_DEA_number, group by level, community, year, and  month. These are the monthly counts for measures 3.3.30,  3.3.100, and  3.3.275*/
proc sql;
create table temp_outcome_3_3_counts_m_sub as 
select unique 	count(unique substr_dea_number) as provider_count, 
				community,
				year, 
				month,
				waiver_type
from outcome_3_3_step6
group by community, year, month, waiver_type;
quit;


/*13) From the table created in step 7, count unique Substr_DEA_number, group by max_level, community, year, and  quarter. These are the quarterly counts for measures 3.3.30,  3.3.100, and  3.3.275*/
proc sql;
create table temp_outcome_3_3_counts_q_sub as 
select unique 	count(unique substr_dea_number) as provider_count, 
				community,
				year, 
				quarter,
				max_level as waiver_type
from outcome_3_3_step7
group by community, year, quarter, waiver_type;
quit;


/*14) From the table created in step 8, count unique Substr_DEA_number, group by max_level, community, and year. These are the annual counts for measures 3.3.30,  3.3.100, and  3.3.275*/
proc sql;
create table temp_outcome_3_3_counts_y_sub as 
select unique 	count(unique substr_dea_number) as provider_count, 
				community,
				year,
				max_level as waiver_type
from outcome_3_3_step8
group by community, year, waiver_type;
quit;


/*DEA date range may differ from PMP date range. As of mid-2020, the DEA data starts in June 2019*/
proc sql;
create table dea_date_range0 as
select unique 	year, 
				month, 
				qtr(mdy(month,1,year)) as quarter
from dea0;
quit;


proc sql;
create table dea_month_count1 as
select unique 	year,
				count(unique month) as month_count
from dea_date_range0
group by year;
quit;
proc sql;
create table dea_month_count2 as
select unique 	year,
				quarter,
				count(unique month) as month_count
from dea_date_range0
where year not in (20212022) /*new 20221007*/
group by year,quarter;
quit;

data dea_complete;
set dea_month_count1(in=a) dea_month_count2 (in=b);
if a and month_count eq 12 then dea_complete = 1;
if a and month_count ne 12 then dea_complete = 0;

if b and month_count eq 3 then dea_complete = 1;
if b and month_count ne 3 then dea_complete = 0;
drop month_count;
run;


proc sql;
create table all_possible_m_dea as 
select unique a.*
from all_possible_m a, dea_date_range0 b
where a.year = b.year and a.month = b.month;
quit;

proc sql;
create table all_possible_q_dea_temp as 
select unique a.*, b.dea_complete
from all_possible_q a, dea_complete b
where a.year = b.year and a.quarter = b.quarter;
quit;

data all_possible_q_dea; 
set all_possible_q_dea_temp; 
if dea_complete = 0 then complete = 0;
drop dea_complete;
run;


proc sql;
create table all_possible_y_dea_temp as 
select unique a.*,  b.dea_complete
from all_possible_y a, dea_complete b
where a.year = b.year and b.quarter = .;
quit;


data all_possible_y_dea; 
set all_possible_y_dea_temp; 
if dea_complete = 0 then complete = 0;
drop dea_complete;
run;

proc sql;
create table waiver_types as 
select unique waiver_type 
from dea0
where waiver_type in (30, 100, 275);
quit;


proc sql;
create table all_possible_m_dea_sub as
select *
from all_possible_m_dea, waiver_types;
quit;

proc sql;
create table all_possible_q_dea_sub as
select *
from all_possible_q_dea, waiver_types;
quit;

proc sql;
create table all_possible_y_dea_sub as
select *
from all_possible_y_dea, waiver_types;
quit;

proc sort data=temp_outcome_3_3_counts_m; by community year month; run;
proc sort data=temp_outcome_3_3_counts_q; by community year quarter; run;
proc sort data=temp_outcome_3_3_counts_y; by community year; run;
proc sort data=temp_outcome_3_3_counts_m_sub; by community year month waiver_type; run;
proc sort data=temp_outcome_3_3_counts_q_sub; by community year quarter waiver_type; run;
proc sort data=temp_outcome_3_3_counts_y_sub; by community year waiver_type; run;

proc sort data=all_possible_m_dea; by community year month; run;
proc sort data=all_possible_q_dea; by community year quarter; run;
proc sort data=all_possible_y_dea; by community year; run;
proc sort data=all_possible_m_dea_sub; by community year month 	waiver_type; run;
proc sort data=all_possible_q_dea_sub; by community year quarter waiver_type; run;
proc sort data=all_possible_y_dea_sub; by community year waiver_type; run;


data outcome_3_3_counts_m; merge all_possible_m_dea temp_outcome_3_3_counts_m (in=b); by community year month; if not b then provider_count = 0; run;
data outcome_3_3_counts_q; merge all_possible_q_dea temp_outcome_3_3_counts_q (in=b); by community year quarter;  if not b then provider_count = 0; run;
data outcome_3_3_counts_y; merge all_possible_y_dea temp_outcome_3_3_counts_y (in=b); by community year;  if not b then provider_count = 0; run;
data outcome_3_3_counts_m_sub; merge all_possible_m_dea_sub temp_outcome_3_3_counts_m_sub (in=b); by community year month waiver_type;  if not b then provider_count = 0; run;
data outcome_3_3_counts_q_sub; merge all_possible_q_dea_sub temp_outcome_3_3_counts_q_sub (in=b); by community year quarter waiver_type; if not b then provider_count = 0;  run;
data outcome_3_3_counts_y_sub; merge all_possible_y_dea_sub temp_outcome_3_3_counts_y_sub (in=b); by community year waiver_type;  if not b then provider_count = 0; run;


data outcome_3_3_counts;
length measureid $10;
set outcome_3_3_counts_m (in=a)
	outcome_3_3_counts_q (in=b)
	outcome_3_3_counts_y (in=c)
	outcome_3_3_counts_m_sub (in=d)
	outcome_3_3_counts_q_sub (in=e)
	outcome_3_3_counts_y_sub (in=f);

if a or b or c then measureid = '3.3';
if d or e or f then do;
	if waiver_type = 30 then measureid  = '3.3.30';
	if waiver_type = 100 then measureid  = '3.3.100';
	if waiver_type = 275 then measureid  = '3.3.275';
end;

if provider_count in (1,2,3,4) then numerator = -88888;
else numerator = provider_count;


/*only keep annual for the evaluation year*/
if year = 20212022 then do;
	if month ne . or quarter ne . then delete; 
end;



drop waiver_type provider_count;
run;

proc sort data=outcome_3_3_counts; by measureid community year quarter month; run;







/**************************************************************************************************/
/******************************************* Outcome 3.4 ******************************************/
/*Number of providers who actively prescribe buprenorphine products that are FDA approved for OUD */
/**************************************************************************************************/
/**************************************************************************************************/


proc sql;
create table outcome_3_4_step01_orig as
select unique 	patient_id,
				year_filled as year,
				quarter_filled as quarter,	
			  	month_filled as month,
				substr(dea_prescriber,2,8) as provider /*substring to remove the the first character -- in MA the first character is sometimes X, sometimes not, for same provider*/
from hcs_bup_18
where dea_prescriber ne '';
quit;


data outcome_3_4_step01_eval;
set outcome_3_4_step01_orig;
where 	(year = 2021 and month in (7,8,9,10,11,12)) or
		(year = 2022 and month in (1,2,3,4,5,6));
year = 20212022;
drop quarter month;
run;



data outcome_3_4_step01;
set outcome_3_4_step01_orig
	outcome_3_4_step01_eval:;
run;


/**********************************************************/
/*join with residence tables (using) residence of patients*/
/**********************************************************/
proc sql;
create table outcome_3_4_step02 as
select unique a.provider, a.patient_id, a.year, a.month, b.community
from outcome_3_4_step01 a, step_j b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.month = b.month;
quit;

proc sql;
create table outcome_3_4_step03 as
select unique a.provider, a.patient_id, a.year, a.quarter, b.community
from outcome_3_4_step01 a, step_k b
where 	a.patient_id = b.patient_id and
		a.year = b.year and 
		a.quarter = b.quarter;
quit;

proc sql;
create table outcome_3_4_step04 as
select unique a.provider, a.patient_id, a.year, b.community
from outcome_3_4_step01 a, step_l b
where 	a.patient_id = b.patient_id and
		a.year = b.year;
quit;

/************************************/
/*********** count months ***********/
/************************************/

proc sql;
create table temp_3_4_counts_m as
select unique 	a.community, 
				a.year, 
				a.month,
				b.complete,
				count(unique a.provider) as provider_count	
from outcome_3_4_step02 a, months b
where a.year = b.year and
	  a.month = b.month	
group by a.community, a.year, a.month;
quit;

data outcome_3_4_counts_m; 
merge all_possible_m (in=x) temp_3_4_counts_m (in=y); by community year month;
if x;
if not y then provider_count = 0;
run;

/************************************/
/************************************/
/************************************/



/**************************************************/
/***************** count quarters *****************/
/**************************************************/


proc sql;
create table temp_3_4_counts_q as
select unique 	a.community, 
				a.year, 
				a.quarter,
				b.complete,
				count(unique a.provider) as provider_count	
from outcome_3_4_step03 a, quarters b
where a.year = b.year and
	  a.quarter = b.quarter	
group by a.community, a.year, a.quarter;
quit;


data outcome_3_4_counts_q; 
merge all_possible_q (in=x) temp_3_4_counts_q (in=y); by community year quarter;
if x;
if not y then provider_count = 0;
run;



/***********************************************/
/***************** count years *****************/
/***********************************************/

proc sql;
create table temp_3_4_counts_y as
select unique 	a.community, 
				a.year, 
				b.complete,
				count(unique a.provider) as provider_count	
from outcome_3_4_step04 a, years b
where a.year = b.year
group by a.community, a.year;
quit;

data outcome_3_4_counts_y; 
merge all_possible_y (in=x) temp_3_4_counts_y (in=y); by community year;
if x;
if not y then provider_count = 0;
run;



data outcome_3_4_counts;
set outcome_3_4_counts_m 
	outcome_3_4_counts_q 
	outcome_3_4_counts_y;

if provider_count in (1,2,3,4) then numerator = -88888; /*suppression*/
else numerator = provider_count;


/*only keep annual for the evaluation year*/
if year = 20212022 then do;
	if month ne . or quarter ne . then delete; 
end;

if year in (20172018,
			20182019,
			20192020,
			20202021,
			20222023) then delete;

drop provider_count;
run;



/****************************************************************************************************/
/****************************************************************************************************/
/****************************************************************************************************/
/****************************************************************************************************/
/****************************************************************************************************/


/**************************************************************************************************************/
/**************************************************************************************************************/
/**************************************************************************************************************/
/**************************************************************************************************************/
/**************************************************************************************************************/




%macro set_counts(newvar, measure);
data outcome_&measure._counts; 
length community $100 year quarter month 8;
set outcome_&measure._counts_m 
	outcome_&measure._counts_q 
	outcome_&measure._counts_y; 

/*-88888 is suppression. some annual stratified records are already suppressed above due to reciprocal suppression*/
if patient_count in (1,2,3,4,-88888) then &newvar = -88888;
if patient_count in (0) or patient_count ge 5 then &newvar = patient_count;



/*NEW 20220907, measure 2.5.1 needs all study years in order to create lagged denominators for 2.7.1. All other measures just need the evaluation year 20212022*/
if "&measure" not in ('2_5_1') and year > 20002000 and year ne 20212022 then delete;


drop patient_count strat_supp_count strat_type;
run;

proc sort data=outcome_&measure._counts; by community year quarter month; run;


%mend set_counts;


%set_counts(numerator, 2_5_1);
%set_counts(numerator, 2_7_1);

%set_counts(numerator, 2_13_a);
%set_counts(numerator, 2_13_b);
%set_counts(numerator, 2_13_c);
%set_counts(numerator, 2_13_d);
%set_counts(numerator, 2_13_all);

%set_counts(numerator, 2_18_numer);
%set_counts(denominator, 2_18_denom);

%set_counts(numerator, 3_1);



data outcome_2_18_counts; merge outcome_2_18_numer_counts outcome_2_18_denom_counts; by community year quarter month; run;
 




proc sql;
create table for_incomplete as
select unique (&end_date - 38) as end_minus_38 format date9.,
		year(&end_date - 38) as year_for_incomplete,
		qtr(&end_date - 38) as quarter_for_incomplete,
		month(&end_date - 38) as month_for_incomplete
from months;*dummy dataset;
run;





proc sql;
create table for_incomplete as
select unique (&end_date - 26) as end_minus_26 format date9.,
		year(&end_date - 26) as year_for_incomplete,
		qtr(&end_date - 26) as quarter_for_incomplete,
		month(&end_date - 26) as month_for_incomplete
from months;*dummy dataset;
run;



proc sql;
create table for_incomplete as
select unique (&end_date - 27) as end_minus_27 format date9.,
		year(&end_date - 27) as year_for_incomplete,
		qtr(&end_date - 27) as quarter_for_incomplete,
		month(&end_date - 27) as month_for_incomplete
from months;*dummy dataset;
run;



%macro incomp(measure);

proc sql;
create table outcome_&measure._counts_revised0
as select *
from outcome_&measure._counts, for_incomplete;
quit;

data outcome_&measure._counts_revised;
set outcome_&measure._counts_revised0;

/*yearly*/
if month = . and quarter = . then do;
	if year ne 20212022 and year ge year_for_incomplete then complete = 0;
	if year eq 20212022 and end_minus_27 ge mdy(06,30,2022) then complete = 1; /*new 20221108*/
end;

/*quarterly*/
if quarter ne . then do;
	if year > year_for_incomplete then complete = 0;
	if year = year_for_incomplete and quarter ge quarter_for_incomplete then complete = 0;
end;

/*monthly*/
if month ne . then do;
	if year > year_for_incomplete then complete = 0;
	if year = year_for_incomplete and month ge month_for_incomplete then complete = 0;
end;

drop end_minus_27 year_for_incomplete quarter_for_incomplete month_for_incomplete;
run;
%mend incomp;

%incomp(2_13_a);
%incomp(2_13_all);









/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/
/******************************************************************************************/

/*************************************************************************************************************************/
/****************************The PROC EXPORTs below will produce one file with multiple tables****************************/
/*****************************Set the &export_path macro variable at the top of the program ******************************/
/*************************************************************************************************************************/

proc export data=outcome_2_5_1_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_5_1; run;
proc export data=outcome_2_7_1_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_7_1; run;
proc export data=outcome_2_13_a_counts_revised outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_13A; run;
proc export data=outcome_2_13_b_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_13B; run;
proc export data=outcome_2_13_c_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_13C; run;
proc export data=outcome_2_13_d_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_13D; run;
proc export data=outcome_2_13_all_counts_revised outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; sheet=hcs_2_13_combined;  run;
proc export data=outcome_2_18_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; sheet=hcs_2_18; run;
proc export data=outcome_3_1_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_3_1; run;
proc export data=outcome_3_3_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_3_3; run;
proc export data=outcome_3_4_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_3_4; run;


option compress=yes;
title; footnote; libname _all_; filename _all_;
proc datasets library=work memtype=data kill; quit; run;
ods graphics off;

options mergenoby=error;
%let rundate = %sysfunc(today(),yymmddn8.);


/********************************************************************************************************************/
/**************************Set the export path for the final dataset of counts by community**************************/
/********************************************************************************************************************/

%let export_path = \\dohfile02\phig\PHIG_documents\Grants\Prescription Drug Overdose - CDC Grant\Special Projects\HEALing\PMP\PMP Measures;

/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/


/******************************************************************************/
/*******************Import list of waived providers from DEA*******************/
/******************************************************************************/

PROC IMPORT OUT= WORK.DEA00
            DATAFILE= "C:\Users\panyue\Box\1 Healing Communities\Data Issues\1 1 1 1 Wave 2\Synthetic Data\Files\Synth Data2000WaiverPrescribers.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
	 GUESSINGROWS=60000;
RUN;



data DEA0; 
length county $100.;
format county $100.;

set DEA00;

/*  ADD for SYNTHETIC DATA DAN  */
month=month(FILE_DATE);
year=year(FILE_DATE);


if County = 'A' then do; County  = 'Broome'; reporterid = '333'; zip_char = '13737'; end;
if County = 'B' then do; County  = 'Cayuga'; reporterid = '334'; zip_char = '13021'; end;
length county $100.;


if month in (1,2,3) then quarter=1;
if month in (4,5,6) then quarter=2;
if month in (7,8,9) then quarter=3;
if month in (19,11,12) then quarter=4;/*END ADD */
waiver_type=PatientLimit;
drop waiver_type1;
run;

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/



/**************************************************************************************************************/
/**************************Set the import path for the NDC lists and define filenames**************************/
/**************************************************************************************************************/

/*Pan, please update import path to wherever you put the merged_NDC_20220825 file*/ 
/*%let import_path = \\doh-smb\doh_shared\Projects\BNE\BNE_SCRIPT_DATA\Files;*/
%let import_path = C:\Users\panyue\Box\1 Healing Communities\Data Issues\1 1 1 1 Wave 2\Synthetic Data\Files;


/*LRH - Pan, if you can, get ahold of this merged_NDC_20220825.xlsx file, so you can 
use the actual NDC codes used to run this for NYS*/ 
/* LRH - Pan, Please adjust import path above to match where you put the file*/ 
%let bup_file = Merged_NDC_20220825.xlsx;
%let opioid_file = Merged_NDC_20220825.xlsx;
%let benzo_file = Merged_NDC_20220825.xlsx;

*LIBNAME pmplib '\\2UA64226CP\Healing PMP\DATA'; 
*LIBNAME fmtbasic '\\2UA64226CP\Healing PMP';
/*Pan, please adjust these libname locations to match wherever you want this stuff stored*/ 
/*LIBNAME pmplib '\\doh-smb\doh_shared\Projects\BNE\BNE_SCRIPT_DATA\Data';*/
/*LIBNAME fmtbasic '\\doh-smb\doh_shared\Projects\BNE\BNE_SCRIPT_DATA';*/

LIBNAME pmplib 'C:\Users\panyue\Box\1 Healing Communities\Data Issues\1 1 1 1 Wave 2\Synthetic Data\Files\pmplib';
LIBNAME fmtbasic 'C:\Users\panyue\Box\1 Healing Communities\Data Issues\1 1 1 1 Wave 2\Synthetic Data\Files\fmtbasic';

/*Pan, I don't think this libname is being used in current code, could comment out*/ 
/*libname test 'C:\Users\vxn09\Desktop\PMP Practice';*/
LIBNAME test 'C:\Users\panyue\Box\1 Healing Communities\Data Issues\1 1 1 1 Wave 2\Synthetic Data\Files\NYS PDMP codes and dependencies\test';


*LIBNAME  pdmplib '\\10.50.79.64\opioid\data';
/*%include "\\doh-smb\doh_shared\Projects\BNE\BNE_SCRIPT_DATA\CHIR_Format_new.sas";*/
%include "C:\Users\panyue\Box\1 Healing Communities\Data Issues\1 1 1 1 Wave 2\Synthetic Data\Files\NYS PDMP codes and dependencies\CHIR_Format_new.sas";
*libname x '\\2UA64226CP\Healing PMP\DATA';
OPTIONS FMTSEARCH=(FMTBASIC.FORMATS) obs=max symbolgen mprint;
proc format library=fmtbasic cntlout=outfmt;
run;



/*****************************************************************************************/
/*****************************************************************************************/
/*****************************************************************************************/


PROC IMPORT OUT= WORK.bup0
            DATAFILE= "&import_path/&bup_file" 
            DBMS=XLSX REPLACE;
     SHEET="Bup"; 
     GETNAMES=YES;
RUN;

proc sql;
create table bup as
select unique ndc_upc_hri as ndc_char label = 'ndc_char'
from bup0
where ndc_upc_hri ne '';
quit;

/*****************************************************************************************/

PROC IMPORT OUT= WORK.benzo0
            DATAFILE= "&import_path/&benzo_file" 
            DBMS=XLSX REPLACE;
     SHEET="Benzo"; 
     GETNAMES=YES;
RUN;

proc sql;
create table benzo as
select unique ndc_upc_hri as ndc_char label = 'ndc_char'
from benzo0
where ndc_upc_hri ne '';
quit;


/*****************************************************************************************/

/*PROC IMPORT OUT= WORK.opioid0
            DATAFILE= "&import_path/&opioid_file" 
            DBMS=XLSX REPLACE;
     SHEET="NDC"; 
     GETNAMES=YES;
RUN;

data opioid1;
set opioid0;

ndc_char = ndc_upc_hri;
mme_conversion_factor = mme;
strength_per_unit = strength_unit;

if long_short_acting = 'LA' then long_act = 1;
if long_short_acting = 'SA' then long_act = 0;

keep ndc_char 	 long_act 	 mme_conversion_factor 	 strength_per_unit;
run;
*/
PROC IMPORT OUT= WORK.opioid0
            DATAFILE= "&import_path/&opioid_file" 
            DBMS=XLSX REPLACE;
     SHEET="OP"; 
     GETNAMES=YES;
RUN;

data opioid1;
set opioid0;

ndc_char = ndc_upc_hri;
mme_conversion_factor = mme;
strength_per_unit = strength_unit;

if long_short_acting = 'LA' then long_act = 1;
if long_short_acting = 'SA' then long_act = 0;

keep ndc_char 	 long_act 	 mme_conversion_factor 	 strength_per_unit;
run;

proc sql;
create table opioid as 
select unique *
from opioid1;
quit;
/*********************************************************************************************/
/*Read in PMP data*/
/********************************************************************************************

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
*/

/*********************************************************************************************/
/*********************************************************************************************/
/*********************************************************************************************/
/*Step A:Create macro variables that contain the start date and end date of the data being 
analyzed. If the beginning of the study period is January 1, 2018, the start date of the 
data analyzed should be July 1, 2017 because six months of records are needed for look-back. 
The end date should not exceed the date of the available complete PMP data.
/*********************************************************************************************/

%let start_date = mdy(07,01,2018);
%let end_date = mdy(12,31,2022);
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
set years0;
if mod(year,4) eq 0 then do; 
	if days lt 366 then complete = 0;
	if days eq 366 then complete = 1;
end;

if mod(year,4) ne 0 then do; 
	if days lt 365 then complete = 0;
	if days eq 365 then complete = 1;
end;

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

/********************************************************************************************************************************************/
/********************************************************************************************************************************************/
/********************************************************************************************************************************************/




/*********************************************************************************************/
/*Step B: Create a table of HCS communities. Include any information you will need in order to */
/*join this table with the PMP data (ZIP codes, city/town names, county names, etc.).*/
/********************************************************************************************

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
quit;*/

data zip0;
set pmplib.zip;
keep fips county cos zipcode;
run;

PROC IMPORT OUT= WORK.HCS_zips1   DATAFILE= "C:\Users\panyue\Box\1 Healing Communities\Data Issues\1 1 1 1 Wave 2\Synthetic Data\Files\Zipcodes for 3 communities.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="HCS_communities$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

data hcs_zips2;
set HCS_zips1;
zip_char=put(ZIP_code,z5.);
hcs=1;
drop ZIP_code;
run;
proc sql;
create table all_zips as
select a.*, b.*
from zip0 as a 
left join hcs_zips2 as b
on a.zipcode=b.zip_char;
quit;

/*YH-For measure 3.3 only, apply HCS community selections in the zips 09/24/2020*/
data zips;
set all_zips;
length community $100.;
community=county;
if county eq 'Suffolk' and town ne '' then community=town;
else if  county eq 'Suffolk' and town eq '' then community='Rest of Suffolk';
if county eq 'Erie' and town ne '' then community=town;
else if  county eq 'Erie' and town eq '' then community='Rest of Erie';
if county eq 'Monroe' and town ne '' then community=town;
else if  county eq 'Monroe' and town eq '' then community='Rest of Monroe';
zip_char=zipcode ;
hcs=1;
keep zipcode cos community 	zip_char hcs;
/*if community in ("Broome", "Cayuga", "Chautauqua", "Columbia", "Cortland",  
"Genesee", "Greene", "Lewis",  "Orange", "Putnam",  "Sullivan", "Ulster", "Yates", 
 "Suffolk", "Erie", "Monroe", "Rochester", "Brookhaven Township", "Buffalo", "Rest of Erie",
"Rest of Monroe", "Rest of Suffolk");*/
run;
/*********************************************************************************************/
/*********************************************************************************************/
/*********************************************************************************************/




/*******************************************************************************************/
/*Step C: From the PMP database, select the IDs of all patients who filled a prescription***/
/*while a resident of an HCS community between the dates defined in step A. ****************/
/*******************************************************************************************/
 
data pmp_all;
/*set pmplib.pmp_all;*/
/*set pmplib.healingpmp2021 pmplib.healingpmp2022;*/
set tmp.all_records_step_d;
length patient_id $100;
ndc_char = put(ndc, 11.);
/*merge pmp_hcs_ids (in=a) pmp_all (in=b); by patient_id;*/
/*if a and b;*/

if PatientCounty = 'A' then do; County  = 'Broome'; reporterid = '333'; zip_char = '13737'; end;
if PatientCounty = 'B' then do; County  = 'Cayuga'; reporterid = '334'; zip_char = '13021'; end;

/*length patient_id $100. ;*/
/*patient_id=put(patientid,12.);*/
/*if patient_subset=1;*/
/*if vet=0;*/
dea_prescriber = prescriberdea;
filldate=datefilled;
DATE_RX_WRITTEN=DateWritten;
PATIENT_BIRTH_DATE=patientdob ;

where datefilled ge &start_date and datefilled le &end_date;
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



/**************************************************************************************************************/
/************************************************ Measure 3.3 *************************************************/
/***************NUMBER OF PROVIDERS WITH A DATA 2000 WAIVER WHO ACTIVELY PRESCRIBE BUPRENORPHINE***************/
/**************************************************************************************************************/
/**************************************************************************************************************/

/*Step 1 is importing the DEA data*/

/*2) Create a new variable that is a substring of the DEA number that excludes the first character. Drop the full DEA number*/


/*YH changed below*/
data outcome_3_3_step2; set dea0;
format community $23.;
substr_dea_number = substr(dea_reg_num, 2,8);

community1=scan(COUNTY,1,' ');
if community1="Erie--Outer" then community="Rest of Erie";
else if community1="Monrore--Outer" then community="Rest of Monroe";
else if community1="Suffolk--Outer" then community="Rest of Suffolk";
else community=community1;

loc=index(COUNTY,'(');
if loc=6 then community="Buffalo";
else if loc=8 then community="Rochester";
else if loc=9 then community="Brookhaven Township";
drop dea_reg_num community1 loc;
run;


/*3) From the table of buprenorphine prescriptions from the PDMP dataset created in step M above, */
/*select all unique combinations of year written, month written, and the prescriber’s DEA number.


proc sql;
create table outcome_3_3_step3 as
select unique 	year_written, 
				month_written, 
				dea_prescriber
from hcs_bup_18;
quit;

/*new 20240419 - restrict to patients 18+*/
proc sql; 
create table outcome_3_3_step3_new as
select unique 	year(a.DATE_RX_WRITTEN) as year_written, 
				month(a.DATE_RX_WRITTEN) as month_written, 
				dea_prescriber
from pmp_all a, bup b
where 	a.DATE_RX_WRITTEN ne . and
		a.ndc_char = b.ndc_char and 
		int(yrdif(a.PATIENT_BIRTH_DATE, a.filldate,'ACTUAL'))  ge 18 ;
quit;


/*4) Create a new variable in the table created in step 3 that is the substring of the prescribers’ DEA number */
/*that excludes the first character. Drop the variable with the full DEA number.*/


data outcome_3_3_step4; set outcome_3_3_step3_new;
substr_dea_number = substr(dea_prescriber, 2,8);
drop dea_prescriber;
run;


/*5)select unique records from the table created in step 4*/
proc sql;
create table outcome_3_3_step5 as 
select unique *
from outcome_3_3_step4;
quit;


/*6) Join the table from step 2 and step 5 on year, month, and the substring of the prescriber’s DEA number. Keep only the records that match.*/

proc sql;
create table outcome_3_3_step6 as
select unique a.*
from outcome_3_3_step2 a, outcome_3_3_step5 b
where 	a.year = b.year_written and 
		a.month = b.month_written and
		a.substr_dea_number = b.substr_dea_number;
quit;



/*7) From the table created in step 6, select unique Substr_DEA_number, year, quarter, and each provider’s maximum prescriber level in each quarter.*/
proc sql;
create table outcome_3_3_step7 as
select unique	substr_dea_number,
				year, 
				quarter, 
				community, 
				max(waiver_type) as waiver_type
from outcome_3_3_step6
group by substr_dea_number, 
		 year, 
		 quarter;
quit; 

/*8) From the table created in step 6, select unique Substr_DEA_number, year, and each provider’s maximum prescriber level in each year.*/
proc sql;
create table outcome_3_3_step8 as
select unique	substr_dea_number,
				year, 
				community, 
				max(waiver_type) as waiver_type
from outcome_3_3_step6
group by substr_dea_number, 
		 year;
quit; 


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
proc sort data=all_possible_q_dea_sub;
 by community year quarter waiver_type;
run;

proc sql;
create table all_possible_y_dea_sub as
select *
from all_possible_y_dea, waiver_types;
quit;
proc sort data=all_possible_m_dea_sub;
by community year month waiver_type;
run;
proc sort data=all_possible_y_dea_sub;
 by community year waiver_type;
run;


%macro count_months(measure, dset);
proc sql;
create table temp_&measure._counts_m as
select unique 	a.community, 
				a.year, 
				a.month,
				b.complete,
				count(unique a.substr_dea_number) as provider_count	
from &dset a, months b
where a.year = b.year and
	  a.month = b.month	
group by a.community, a.year, a.month;
quit;

data outcome_&measure._counts_m1; 
merge all_possible_m_dea (in=x) temp_&measure._counts_m (in=y); by community year month;
if x;
if not y then provider_count = 0;
run;

data outcome_&measure._counts_m2;
 set &dset;
if community in ('Brookhaven Township' 'Rest of Suffolk') then community='Suffolk';
if community in ('Buffalo' 'Rest of Erie') then community='Erie';
if community in ('Rochester' 'Rest of Monroe') then community='Monroe';
where  community in ('Brookhaven Township' 'Rest of Suffolk' 'Buffalo' 'Rest of Erie' 'Rochester' 'Rest of Monroe');
run;

proc sql noprint;
create table outcome_&measure._counts_m3 as 
select unique a.community, a.year, a.month,b.complete, count(unique substr_dea_number) as provider_count
from outcome_&measure._counts_m2 a, months b
where a.year = b.year and
	  a.month = b.month	
group by a.community, a.year, a.month;
quit;

data outcome_&measure._counts_m;
set outcome_&measure._counts_m1 outcome_&measure._counts_m3;
run;

%mend count_months;

%macro count_qtrs(measure, dset);
proc sql;
create table temp_&measure._counts_q as
select unique 	a.community, 
				a.year, 
				a.quarter,
				b.complete,
				count(unique a.substr_dea_number) as provider_count	
from &dset a, quarters b
where a.year = b.year and
	  a.quarter = b.quarter	
group by a.community, a.year, a.quarter;
quit;


data outcome_&measure._counts_q1; 
merge all_possible_q_DEA (in=x) temp_&measure._counts_q (in=y); by community year quarter;
if x;
if not y then provider_count = 0;
run;

data outcome_&measure._counts_q2;
set &dset;
if community in ('Brookhaven Township' 'Rest of Suffolk') then community='Suffolk';
if community in ('Buffalo' 'Rest of Erie') then community='Erie';
if community in ('Rochester' 'Rest of Monroe') then community='Monroe';
where  community in ('Brookhaven Township' 'Rest of Suffolk' 'Buffalo' 'Rest of Erie' 'Rochester' 'Rest of Monroe');
run;

proc sql noprint;
create table outcome_&measure._counts_q3 as 
select unique a.community, a.year, a.quarter,b.complete, count(unique substr_dea_number) as provider_count
from outcome_&measure._counts_q2 a, quarters b
where a.year = b.year and
	  a.quarter = b.quarter	
group by a.community, a.year, a.quarter;
quit;

data outcome_&measure._counts_q;
set outcome_&measure._counts_q1 outcome_&measure._counts_q3;
run;

%mend count_qtrs;
%macro count_years(measure, dset);
proc sql;
create table temp_&measure._counts_y as
select unique 	a.community, 
				a.year, 
				b.complete,
				count(unique a.substr_dea_number) as provider_count	
from &dset a, years b
where a.year = b.year
group by a.community, a.year;
quit;


data outcome_&measure._counts_y1; 
merge all_possible_y_DEA (in=x) temp_&measure._counts_y (in=y); by community year;
if x;
if not y then provider_count = 0;
run;

data outcome_&measure._counts_y2; 
set &dset; 
if community in ('Brookhaven Township' 'Rest of Suffolk') then community='Suffolk';
if community in ('Buffalo' 'Rest of Erie') then community='Erie';
if community in ('Rochester' 'Rest of Monroe') then community='Monroe';
where  community in ('Brookhaven Township' 'Rest of Suffolk' 'Buffalo' 'Rest of Erie' 'Rochester' 'Rest of Monroe');
run;

proc sql noprint;
create table outcome_&measure._counts_y3 as 
select unique a.community, a.year,b.complete,  count(unique substr_dea_number) as provider_count
from outcome_&measure._counts_y2 a, years b
where a.year = b.year
group by a.community, a.year;
quit;

data outcome_&measure._counts_y;
set outcome_&measure._counts_y1 outcome_&measure._counts_y3;
run;

%mend count_years;



%count_months(3_3, outcome_3_3_step6);
%count_qtrs(3_3, outcome_3_3_step7);
%count_years(3_3, outcome_3_3_step8);






%macro count_months(measure, dset);
proc sql;
create table temp_&measure._counts_m_sub as
select unique 	a.community, 
				a.year, 
				a.month,
                a.waiver_type,
				b.complete,
				count(unique a.substr_dea_number) as provider_count
from &dset a, months b
where a.year = b.year and
	  a.month = b.month	
group by a.community, a.year, a.month, a.waiver_type;
quit;

data outcome_&measure._counts_m1_sub; 
merge all_possible_m_dea_sub (in=x) temp_&measure._counts_m_sub (in=y); by community year month waiver_type;
if x;
if not y then provider_count = 0;
run;

data outcome_&measure._counts_m2_sub;
 set outcome_&measure._counts_m1_sub;
if community in ('Brookhaven Township' 'Rest of Suffolk') then community='Suffolk';
if community in ('Buffalo' 'Rest of Erie') then community='Erie';
if community in ('Rochester' 'Rest of Monroe') then community='Monroe';
where  community in ('Brookhaven Township' 'Rest of Suffolk' 'Buffalo' 'Rest of Erie' 'Rochester' 'Rest of Monroe');
run;

proc sql noprint;
create table outcome_&measure._counts_m3_sub as 
select unique a.community, a.year, a.month,b.complete, a.waiver_type, count(unique substr_dea_number) as provider_count
from outcome_&measure._counts_m2_sub a, months b
where a.year = b.year and
	  a.month = b.month	
group by a.community, a.year, a.month, a.waiver_type;
quit;

data outcome_&measure._counts_m_sub;
set outcome_&measure._counts_m1_sub outcome_&measure._counts_m3_sub;
run;

%mend count_months;

%macro count_qtrs(measure, dset);
proc sql;
create table temp_&measure._counts_q_sub as
select unique 	a.community, 
				a.year, 
				a.quarter,
				a.waiver_type,
				b.complete,
				count(unique a.substr_dea_number) as provider_count	
from &dset a, quarters b
where a.year = b.year and
	  a.quarter = b.quarter	
group by a.community, a.year, a.quarter, a.waiver_type;
quit;


data outcome_&measure._counts_q1_sub; 
merge all_possible_q_DEA_sub (in=x) temp_&measure._counts_q_sub (in=y); by community year quarter waiver_type;
if x;
if not y then provider_count = 0;
run;

data outcome_&measure._counts_q2_sub;
set &dset;
if community in ('Brookhaven Township' 'Rest of Suffolk') then community='Suffolk';
if community in ('Buffalo' 'Rest of Erie') then community='Erie';
if community in ('Rochester' 'Rest of Monroe') then community='Monroe';
where  community in ('Brookhaven Township' 'Rest of Suffolk' 'Buffalo' 'Rest of Erie' 'Rochester' 'Rest of Monroe');
run;

proc sql noprint;
create table outcome_&measure._counts_q3_sub as 
select unique a.community, a.year, a.quarter,a.waiver_type, b.complete, count(unique substr_dea_number) as provider_count
from outcome_&measure._counts_q2_sub a, quarters b
where a.year = b.year and
	  a.quarter = b.quarter	
group by a.community, a.year, a.quarter, a.waiver_type;
quit;

data outcome_&measure._counts_q_sub;
set outcome_&measure._counts_q1_sub outcome_&measure._counts_q3_sub;
run;

%mend count_qtrs;
%macro count_years(measure, dset);
proc sql;
create table temp_&measure._counts_y_sub as
select unique 	a.community, 
				a.year, 
                a.waiver_type,
				b.complete,
				count(unique a.substr_dea_number) as provider_count	
from &dset a, years b
where a.year = b.year
group by a.community, a.year, a.waiver_type;
quit;


data outcome_&measure._counts_y1_sub; 
merge all_possible_y_dea_sub (in=x) temp_&measure._counts_y_sub (in=y); by community year waiver_type;
if x;
if not y then provider_count = 0;
run;

data outcome_&measure._counts_y2_sub; 
set &dset; 
if community in ('Brookhaven Township' 'Rest of Suffolk') then community='Suffolk';
if community in ('Buffalo' 'Rest of Erie') then community='Erie';
if community in ('Rochester' 'Rest of Monroe') then community='Monroe';
where  community in ('Brookhaven Township' 'Rest of Suffolk' 'Buffalo' 'Rest of Erie' 'Rochester' 'Rest of Monroe');
run;

proc sql noprint;
create table outcome_&measure._counts_y3_sub as 
select unique a.community, a.year, a.waiver_type, b.complete, count(unique substr_dea_number) as provider_count
from outcome_&measure._counts_y2_sub a, years b
where a.year = b.year
group by a.community, a.year, a.waiver_type;
quit;

data outcome_&measure._counts_y_sub;
set outcome_&measure._counts_y1_sub outcome_&measure._counts_y3_sub;
run;

%mend count_years;


%count_months(3_3_sub, outcome_3_3_step6);
%count_qtrs(3_3_sub, outcome_3_3_step7);
%count_years(3_3_sub, outcome_3_3_step8);



data outcome_3_3_counts;
length measureid $10;
set outcome_3_3_counts_m (in=a)
	outcome_3_3_counts_q (in=b)
	outcome_3_3_counts_y (in=c)
	outcome_3_3_sub_counts_m_sub (in=e)
	outcome_3_3_sub_counts_q_sub (in=f)
	outcome_3_3_sub_counts_y_sub (in=g);

if a or b or c then measureid = '3.3';
if e or f or g then do;
	if waiver_type = 30 then measureid  = '3.3.30';
	if waiver_type = 100 then measureid  = '3.3.100';
	if waiver_type = 275 then measureid  = '3.3.275';
end;

if provider_count in (1,2,3,4,5) then issuppressed = '1';
 numerator = provider_count;


if community="Broome" then ReporterId ="0333";
if community="Cayuga" then ReporterId ="0334";
if community="Chautauqua" then ReporterId ="0335";
if community="Columbia" then ReporterId ="0336";
if community="Cortland" then ReporterId ="0337";
if community="Erie" then ReporterId ="0368";
if community="Buffalo" then ReporterId ="0338";
if community="Genesee" then ReporterId ="0339";
if community="Greene" then ReporterId ="0340";
if community="Lewis" then ReporterId ="0341";
if community="Monroe" then ReporterId ="0369";
if community="Rochester" then ReporterId ="0342";
if community="Orange" then ReporterId ="0343";
if community="Putnam" then ReporterId ="0344";
if community="Suffolk" then ReporterId ="0370";
if community="Brookhaven Township" then ReporterId ="0345";
if community="Sullivan" then ReporterId ="0346";
if community="Ulster" then ReporterId ="0347";
if community="Yates" then ReporterId ="0348";

if community in ("Broome" "Cayuga" "Chautauqua" "Columbia" "Cortland"  
"Genesee" "Greene" "Lewis"  "Orange" "Putnam"  "Sullivan" "Ulster" "Yates" 
 'Suffolk' 'Erie' 'Monroe' 'Rochester' 'Brookhaven Township' 'Buffalo' );

if year ge 2022;
drop provider_count	waiver_type;

run;

proc sort data=outcome_3_3_counts; by measureid community year quarter month; run;




/*************************************************************************************************************************/
/****************************The PROC EXPORTs below will produce one file with multiple tables****************************/
/*****************************Set the &export_path macro variable at the top of the program ******************************/
/*************************************************************************************************************************/


proc export data=outcome_3_3_counts outfile="&export_path.\hcs_pmp_measures3.3_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_3_3; run;





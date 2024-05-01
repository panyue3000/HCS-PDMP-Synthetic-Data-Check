/*Adjusted to run the sanitized/synthetic data received from OH on 3-21-24*/

/*4-16-24 - We're testing changes that will need to be recreated in the main programs, 
including the following: 

1. Measure 3.3 should have CK, MQ, MR, and MS added as DW30 provider types. Copy code from 3.2.
2. Measure 3.3 may need to have the age filter removed, awaiting confirmation.
3. Measure 2.7.1 may need to have continuous macro adjusted to capture retention at any time in month, awaiting feedback and confirmation. 
	- NY, MA, and KY all using same definition, just testing first and last day of month for retention criteria. 
	- NY would lose 2018 data if they adjust definition.
4. Step G should carry forward community from previous month if no observed communtiy in a month. 
5. PMP Sex must also be recreated to carry forward community from previous month.
*/

/*4-18-24 - Now we're discussing moving back to having the age filter in place on 3.3, just 
doing the KY approach of having the HCS filter removed from creation steps for hcs_bup_18. */ 


/*Notes for NY, MA, and anyone else running synthetic code: 
*I've left guidance on where you'll need to adjust your imported files,
	to find my notes please perform a ctrl+F search for "please". */


title; footnote; libname _all_; /*filename _all_;*/ /*removed 1-10-23 because it just writes to log*/
proc datasets library=work memtype=data kill; quit; run;
ods graphics off;

libname tmp "\\isosmb\CCTSEDC\004HEAL3-DataAnalytics\Data Requests\Ohio PDMP Measure Check\Revision_20240418" filelockwait=10; /*LRH added filelockwait 9-16-22 after repeated lock errors with execute statements*/


options validvarname=v7; /* Added to convert numerical column name to valid form */

options mergenoby=error;
%let rundate = %sysfunc(today(),yymmddn8.);
/********************************************************************************************************************/
/**************************Set the export path for the final dataset of counts by community**************************/
/********************************************************************************************************************/
%let export_path = \\isosmb\CCTSEDC\004HEAL3-DataAnalytics\Data Requests\Ohio PDMP Measure Check\Revision_20240418\Files;

/************************************************************************************************************************/

*Define the whole measure period;
%let start_date = mdy(01,01,2017);
%let end_date = mdy(12,31,2023); *The last date of the previous month. ;
/*********************************************************************************************/


/**************************************************************************************************************/
/***************************** Create dataset from updated BUP/OPIOID/BENZO list ******************************/
/**************************************************************************************************************/

/*4-2024: LRH changed to an import of the "KY Medispan Export 20230619.xlsx" lookup tables,
as the KY and OH NDC tables were living files that had gone out of sync, complicating harmonization.*/ 


/*LRH note 4-2024 - to get job done, added blank top row to remove, deleted tcgpid*/
/*NY and MA - Please use your own NDC files, uncomment these import steps only if you 
need to use the NDC files I extracted from the "KY Medispan Export 20230619.xlsx" file
(e.g., if your normal NDC files are living datasets and not already snapshots from this
lookup table, as is the case in KY).*/ 
/*
proc import datafile="&export_path.\opioids.csv"
	out= opioid
	dbms= csv
	replace;
	getnames=yes;
	run;

data opioid;
set opioid;
if _N_ > 1;
ndc_char = ndc_upc_hri;
if longshortacting = 'LA' then long_act = 1;
if longshortacting = 'SA' then long_act = 0;
run;

proc import datafile="&export_path.\bup.csv"
	out= bup
	dbms= csv
	replace;
	getnames=yes;
	run;

data bup;
set bup;
ndc_char = ndc_upc_hri;
if _N_ > 1;
run;

proc import datafile="&export_path.\benzo.csv"
	out= benzo
	dbms= csv
	replace;
	getnames=yes;
	run;

data benzo;
set benzo;
ndc_char = ndc_upc_hri;
if _N_ > 1;
run;

*/
/*NY and MA - as noted above, please only uncomment the lines above if it is necessary to use the 
NDC code tables we're providing*/ 



/************************************************************/
/************************************************************/
/************************************************************/
/*Run original measure code on imported synthetic data, all PDMP code prior to this cut for test*/
/************************************************************/
/************************************************************/
/************************************************************/
/*NY and MA - please note that this file should be inserted into your normal workflow in lieu of the 
various PDMP import steps leading up to the creation of all_records_step_d*/ 
/*NY and MA - please also note that ky was using the tmp. library and this may differ from your
workflow, adjust as needed*/ 
proc import datafile="&export_path.\HCS Synthetic Data Export.csv"
	out= tmp.all_records_step_d
	dbms= csv
	replace;
	getnames=yes;
	run;



/*After import, rename to the expected file for subsequent measure
	code, here all_records_step_d, and convert county and reporterid
	to useful values for matching to lookup tables*/ 

/*NY and MA - please consult the file structure of your usual all_records_step_d and 
	and just naming below as needed. Test consistency with next steps carefully 
	in case a format is not as expected.*/
data tmp.all_records_step_d; 
set tmp.all_records_step_d;
ndc11_char = put (NDC, z11.);
sex = PROPCASE(PatientSex);
patient_id = patientid;
date_filled = datefilled;
days_dispensed = DaysSupply;
dob_inc_missing = PatientDOB;
dea_prescriber = PrescriberDEA;
dea_pharmacy = PharmacyDEA;
date_run_out = date_filled + days_dispensed -1;
writtendate = DateWritten;
HCS = 1;
prescriber_degree = "MD/DO";
metric_quantity = Quantity;
quantity_dispensed = Quantity;
/*NY and MA - Please change the next two lines for your state if you will need to assign 
		a real county ID to A and B. I chose the first two counties in KY, 
		just to get all my later joins to work as expected. */
if PatientCounty="A" then do; county="Bourbon"; ReporterID="0101"; end;
else do; county="Boyd"; ReporterID="0102"; end;
format dob_inc_missing date_filled writtendate date_run_out date9.;
year_filled = year(date_filled) ;
quarter_filled = qtr(date_filled) ;
month_filled = month(date_filled) ;
year_written = year(writtendate) ;
quarter_written = qtr(writtendate) ;
month_written = month(writtendate) ;
*rename  reporterid2=reporterid ndc11_char2=ndc11_char;
run;

/*NY and MA - please note that I recreated this step here, using all_records_step_d rather than pmp_all,
as having this table became necessary later in testing and we had not initally generated it. 
I think it's ok to leave as is, but please cross reference against your normal approach to creating the pmp_hcs_ids.*/

proc sql;
create table tmp.pmp_hcs_ids as
select unique patient_id label = 'Patient ID'
from tmp.all_records_step_d /*changing to all_records_step_d instead of pmp_all for synthetic testing only, 4-16-24, LRH*/
where hcs=1;
quit;

/*DEA file import*/ 

/**************************************************************************************************************/
/************************************************ Measure 3.3 *************************************************/
/***************NUMBER OF PROVIDERS WITH A DATA 2000 WAIVER WHO ACTIVELY PRESCRIBE BUPRENORPHINE***************/
/**************************************************************************************************************/
/**************************************************************************************************************/


/************************************************************/
/************************************************************/
/************************************************************/
/*Run original measure code on imported synthetic data, cutting real DEA data step*/
/************************************************************/
/************************************************************/
/************************************************************/
/*Pan, once you find the 3.3 code please add this in to replace the dea_all step in your code*/ 
proc import datafile="&export_path.\Synth Data2000WaiverPrescribers.csv"
	out= DEA_all
	dbms= csv
	replace;
	getnames=yes;
	run;



/*After import, rename to the expected file for subsequent measure
	code, here all_records_step_d, and convert county and reporterid
	to useful values for matching to lookup tables*/ 
/*Pan, please note that this whole dea_all step will need to be adjusted to match your 3.3 code, when you find it, 
	and may look very different from KY's. The point is to use this data step to rename synthetic data variables
	so that they can be smoothly integrated into real code, as though they aren't fake data*/ 
data DEA_all; 
set DEA_all;
	Business_Activity_Code = substr(DEA_code,1,1);
business_activity_subcode = substr(DEA_code,2,2);
/*4-16-24 - replaced old code*/ 
/*old code*/
/*
	if ((Business_Activity_Code ="C" and business_activity_subcode in ("1","4","B"))
	or (Business_Activity_Code ="M" and business_activity_subcode in ("F","G","H","I","K","L"))) 
	then mark=1;
*/
/*new code*/ 
/*Pan, please note that this is a KY-specific thing, and a source of a previous error - your code may not look 
anything like this. In MA, the provider level is set prior to import of the file. Feel free to reach out when you have
more and I can work with you to adjust*/ 
	if ((Business_Activity_Code ="C" and business_activity_subcode in ("1","4","B","K"))
	or (Business_Activity_Code ="M" and business_activity_subcode in ("F","G","H","I","K","L","Q","R","S")))  
	then mark=1;
dea_extract_dt = FILE_DATE;
format dea_extract_dt date9.;
month = month(dea_extract_dt) ;
year = year(dea_extract_dt) ;
DEA_number = dea_reg_number;
/*NY and MA - Please change the next two lines for your state if you will need to assign 
		a real county ID to A and B. I chose the first two counties in KY, 
		just to get all my later joins to work as expected. */
if COUNTY="A" then do; county2="Bourbon"; zip_code="40324"; city="Paris"; ReporterId='0101'; end;
else do; county2="Boyd"; zip_code="41129"; city="Ashland"; ReporterID='0102'; end;
/*test out my def of DW, plus his patientlimit*/
	if Business_Activity_Code="C" and business_activity_subcode ="1" then DW=30;
	else if Business_Activity_Code="C" and business_activity_subcode ="4" then DW=100;
	else if Business_Activity_Code="C" and business_activity_subcode ="B" then DW=275;
	else if Business_Activity_Code="M" and business_activity_subcode ="F" then DW=30;
	else if Business_Activity_Code="M" and business_activity_subcode ="G" then DW=30;
	else if Business_Activity_Code="M" and business_activity_subcode ="H" then DW=100;
	else if Business_Activity_Code="M" and business_activity_subcode ="I" then DW=100;
	else if Business_Activity_Code="M" and business_activity_subcode ="K" then DW=275;
	else if Business_Activity_Code="M" and business_activity_subcode ="L" then DW=275;
/*added 4-16-24 from 3.2 measure code*/ 
	/*newly added business activity codes and sub-codes that were added for low level prescribers*/ 
    else if Business_Activity_Code="M" and business_activity_subcode ="Q" then DW=30;
	else if Business_Activity_Code="M" and business_activity_subcode ="R" then DW=30;
	else if Business_Activity_Code="M" and business_activity_subcode ="S" then DW=30;
	else if Business_Activity_Code="C" and business_activity_subcode ="K" then DW=30;
drop county;
rename county2=county;
run;

/**************************************************************************************/
/**************************************************************************************/
/**************************************************************************************/
/**************************************************************************************/
/**************************************************************************************/
/**************************************************************************************/
/**************************************************************************************/
/**************************************************************************************/
/**************************************************************************************/
/**************************************************************************************/
/**************************************************************************************/

/*Example macros for exporting files in a format that will easily paste into the KY and OH
comparison sheets, as well as example macros for exporting interim files*/
/*NY and MA - please adapt these to your puposes as needed, or disregard*/ 

/**************************************************************************************/
/**************************************************************************************/
/**************************************************************************************/
/**************************************************************************************/

%macro convert_compare(dset, sheet);

proc sql;
create table t&dset as
/*NY and MA - please note that your method for returning to County A and County B 
will likely differ from mine, depending on what you did in earlier code*/
select case when Reporterid='0101' then 'County A'
			when Reporterid='0102' then 'County B'
			else '' end as Community,
numerator as NY_num,
Denominator as NY_den,
month,
quarter,
year
from &dset
where Reporterid in ('0101','0102') and year in (2020, 2021, 2022, 20212022) /*Pan, please note that this is what study year looks like for
KY and MA. When you have the right code version it should look similar*/ 
order by Community, year, month, quarter
;
quit;

proc export data=t&dset outfile="&export_path.\hcs_pmp_measures_compare_&rundate..xlsx" dbms=xlsx replace; 	sheet=&sheet; run;

%mend;
/*LRH note - Pan, I think once you have all the NYS code you should be able to produce all of the files for these export
steps. You would want to change the first argument in each macro to match whatever the final version of your file for the 
measure update is called*/ 
/*here's what you had in NYS:

proc export data=outcome_2_5_1_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_5_1; run;
proc export data=outcome_2_7_1_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_7_1; run;
proc export data=outcome_2_13_a_counts_revised outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_13A; run;
proc export data=outcome_2_13_b_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_13B; run;
proc export data=outcome_2_13_c_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_13C; run;
proc export data=outcome_2_13_d_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_2_13D; run;
proc export data=outcome_2_13_all_counts_revised outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; sheet=hcs_2_13_combined; run;
proc export data=outcome_2_18_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; sheet=hcs_2_18; run;
proc export data=outcome_3_1_counts outfile="&export_path.\hcs_pmp_measures_&rundate..xlsx" dbms=xlsx replace; 	sheet=hcs_3_1; run;
/*proc export data=final outfile="&export_path.\hcs_pmp_measure3_3_&rundate..xlsx" dbms=xlsx replace; sheet=hcs_3_3; run;
*/
%convert_compare(outcome_2_5_1_counts, '2.5.1');
%convert_compare(outcome_2_7_1_counts, '2.7.1');

%convert_compare(outcome_2_13_a_counts_revised, '2.13A');
%convert_compare(outcome_2_13_b_counts, '2.13B');
%convert_compare(outcome_2_13_c_counts, '2.13C');
%convert_compare(outcome_2_13_d_counts, '2.13D');


%convert_compare(outcome_2_18_counts, '2.18');

%convert_compare(outcome_3_1_counts, '3.1');

/*LRH - these are currently missing in NYS code, didn't update arg1 names, Pan please note*/ 
%convert_compare(Final_outcome_3_3_counts, '3.3');
%convert_compare(FINAL_outcome_3_3_30_counts, '3.3.30');
%convert_compare(FINAL_outcome_3_3_100_counts, '3.3.100');
%convert_compare(FINAL_outcome_3_3_275_counts, '3.3.275');

/*missing in NYS code, didn't update arg 1, pan please note*/ 
%convert_compare(Final_outcome_3_4_counts, '3.4');

%convert_compare(outcome_2_13_all_counts_revised, '2.13.all');


/*add dea export for chad's review*/
data tmp_export;
set tmp_matched;
if DW ne PatientLimit;
run;
/*0 records not matching*/





/*interim file export*/


%macro export_interim(dset, file, sheet);
proc export data=&dset outfile="&export_path.\&file._&rundate..xlsx" dbms=xlsx replace; 	sheet=&sheet; run;
%mend;

%export_interim(outcome_2_5_1_step01, measure_2_5_1, '251_step1');
%export_interim(outcome_2_5_1_step02, measure_2_5_1, '251_final_months');
%export_interim(outcome_2_5_1_step03, measure_2_5_1, '251_final_quarters');
%export_interim(outcome_2_5_1_step04, measure_2_5_1, '251_final_years');
%export_interim(outcome_2_5_1_step04_sy, measure_2_5_1, '251_final_study_years');


*%export_interim(hcs_bup_17_step12, measure_2_7_1, 'bup_17_contin');
*%export_interim(outcome_2_7_1_step01, measure_2_7_1, '271_step7');
%export_interim(outcome_2_7_1_step05, measure_2_7_1, '271_step9');
%export_interim(outcome_2_7_1_step06, measure_2_7_1, '271_final_months');

*%export_interim(hcs_opioid_18_step12, measure_2_13_b, 'opioid_18_contin');
*%export_interim(outcome_2_13_a_step00, measure_2_13_b, 'gap_prior_gte_45');
%export_interim(outcome_2_13_b_step01, measure_2_13_b, '213b_step18');
%export_interim(outcome_2_13_b_step03, measure_2_13_b, '213b_step19');


*%export_interim(tmp.hcs_opioid_17, measure_2_13_c, 'opioid_17');
*%export_interim(outcome_2_13_c_step02, measure_2_13_c, 'mme_per_day');

*%export_interim(outcome_2_13_c_step04, measure_2_13_c, 'mme_total_monthly');
%export_interim(outcome_2_13_c_step12, measure_2_13_c, '213c_step29');
%export_interim(outcome_2_13_c_step17, measure_2_13_c, '213c_step30');


*%export_interim(outcome_2_13_d_step01, measure_2_13_d, 'benzo');
*%export_interim(outcome_2_13_d_step02, measure_2_13_d, 'benzo_per_day');
*%export_interim(outcome_2_13_d_step04, measure_2_13_d, 'days_overlap_calc');
%export_interim(outcome_2_13_d_step10, measure_2_13_d, '213d_step41');
%export_interim(outcome_2_13_d_step12, measure_2_13_d, '213d_step42');
%export_interim(outcome_2_13_d_step17, measure_2_13_d, '213d_final_monthly');

*%export_interim(outcome_3_1_step01, measure_3_1, 'pt_dea_combos');
%export_interim(outcome_3_1_step04, measure_3_1, '31_step4');
%export_interim(outcome_3_1_step06, measure_3_1, '31_step5');
%export_interim(outcome_3_1_step11, measure_3_1, '31_final_monthly');


%export_interim(step_j, communities, 'step_j_monthly');
%export_interim(step_k, communities, 'step_k_quarterly');
%export_interim(step_l, communities, 'step_l_annual');
*/
*%export_interim(outcome_2_13_c_step03, measure_2_13_c, 'mme_total_daily'); /*too large*/
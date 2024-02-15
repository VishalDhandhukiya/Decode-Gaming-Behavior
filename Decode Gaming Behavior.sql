#1) Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0.

Select T1.P_ID,T2.Dev_ID,T1.PName,T2.Difficulty as Difficulty_Level
From player_details as T1 Inner Join level_details as T2 Using(P_ID)
Where T2.Level=0;

#2) Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 stages are crossed.

Select T1.L1_Code,avg(T2.Kill_Count) as Avg_Kill_Count
From player_details as T1 Inner Join level_details as T2 Using(P_ID)
Where T2.Stages_crossed>=3 and T2.Lives_Earned=2
Group by T1.L1_Code;

#3) Find the total number of stages crossed at each difficulty level for Level 2 with players using `zm_series` devices. 
-- Arrange the result in decreasing order of the total number of stages crossed.

Select Difficulty as Difficulty_Level,Sum(stages_crossed) as "No. of Stages Crossed"
From level_details
where level=2 and Dev_ID like "zm%"
Group by Difficulty_Level
order by Sum(stages_crossed) desc;

#4) Extract `P_ID` and the total number of unique dates for those players who have played games on multiple days.

Select T1.P_ID, Count(Distinct(Date(T2.start_datetime))) as "No.of Unique Dates"
From player_details as T1 Inner Join level_details as T2 Using(P_ID)
Group by T1.P_ID
Having Count(Distinct(Date(T2.start_datetime)))>1;

#5) Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the average kill count for Medium difficulty.

Select P_ID,Level,Sum(kill_count) as Kill_Count
From level_details
Where kill_count >(Select avg(kill_count) From level_details where Difficulty="Medium")
Group by P_ID,Level
order by P_ID,Level;

#6) Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level 0. Arrange in ascending order of level.

Select T2.Level,T1.L1_Code as Level_Code,Sum(T2.Lives_Earned) as Lives_Earned
From player_details as T1 Inner Join level_details as T2 Using(P_ID)
Where T2.Level<>0
Group by T2.Level,T1.L1_Code

Union All

Select T2.Level,T1.L2_Code as Level_Code,Sum(T2.Lives_Earned) as Lives_Earned
From player_details as T1 Inner Join level_details as T2 Using(P_ID)
Where T2.Level<>0
Group by T2.Level,T1.L2_Code
Order by Level;

#7) Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using `Row_Number`. Display the difficulty as well.

Select *
From (Select Dev_ID,Difficulty,Score,Row_Number() Over(Partition by Dev_ID Order by Score desc) as Rankk From Level_Details) as Project
Where Rankk<=3;

#8) Find the `first_login` datetime for each device ID.

Select Dev_ID,Start_datetime
From (Select Dev_ID,start_datetime,Row_number() Over(Partition by Dev_ID Order by start_datetime) as Rankk
From level_details) as Project
Where Rankk=1;

#9) Find the top 5 scores based on each difficulty level and rank them in increasing order using `Rank`. Display `Dev_ID` as well.

Select *
From (Select Dev_ID,Difficulty,Score,Rank() Over(Partition by Difficulty Order by Score desc) as Rankk From Level_details) as Project
Where Rankk<=5; 

#10) Find the device ID that is first logged in (based on `start_datetime`) for each player (`P_ID`).
--   Output should contain player ID, device ID, and first login datetime.

Select P_ID,Dev_ID,Start_Datetime
From (Select P_ID,Dev_ID,Start_Datetime,Rank() Over(Partition by P_ID Order by start_Datetime) as Rankk From Level_details) as Project
Where Rankk=1;

#11) For each player and date, determine how many `kill_counts` were played by the player so far.
--   a) Using window functions

Select P_ID,Datee,Kill_Count
From (Select P_ID,Date(Start_datetime) as Datee,SUM(kill_Count) Over(Partition by P_ID,Date(Start_datetime)) as Kill_Count,
	   Row_Number() Over(Partition by P_ID,Date(Start_datetime)) as Row_No
	   From level_details) as Project
Where Row_No=1;


--   b) Without window functions

Select P_ID,Date(Start_datetime) as Datee,Sum(kill_count) as Kill_Count
From level_details
Group by P_ID,Date(Start_datetime);

#12)  Find the cumulative sum of stages crossed over a start_datetime for each `P_ID`

Select P_ID,start_datetime, sum(stages_crossed) Over(partition by P_ID Order by Start_datetime) as Cumulative_of_Stages_crossed
From level_details;

#13)  Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`, excluding the most recent `start_datetime`.

Select P_ID,Start_datetime,Cumulative_of_Stages_crossed
From (
		Select P_ID,start_datetime, sum(stages_crossed) Over(partition by P_ID Order by Start_datetime) as Cumulative_of_Stages_crossed,
	    Row_Number() Over(Partition by P_ID) as Row_NO
		From level_details
	 ) as Mentorness
Where (P_ID,Row_NO) NOT IN 
					   (Select P_ID,MAX(Row_No) as Row_No
						From  
							(Select P_ID,start_datetime, sum(stages_crossed) Over(partition by P_ID Order by Start_datetime) as Cumulative_of_Stages_crossed,
							 Row_Number() Over(Partition by P_ID) as Row_NO
							 From level_details) as Project
							 Group by P_ID);
                             
#14) Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.

Select Dev_ID,P_ID,Total_Score
From  (Select Dev_ID,P_ID,Total_Score,Row_Number() Over(Partition by Dev_ID order by Total_Score desc) as Rankk
	   From(
			Select Dev_ID,P_ID,Sum(Score) as Total_Score 
            From level_details
            Group by Dev_ID,P_ID
            Order by Dev_ID asc,Total_Score desc
            ) as Project) as Mentorness
Where Rankk<=3;

#15) Find players who scored more than 50% of the average score, scored by the sum of scores for each `P_ID`

Select *
From (Select P_ID, Sum(Score) as Total_Score From level_details Group by P_ID) as Mentorness
Where Total_Score>(Select 0.5*Avg(Total_Score) As Avg_Score From ( Select P_ID, Sum(Score) as Total_Score From level_details Group by P_ID) as Project);

#16) Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID` and rank them in increasing order using `Row_Number`. 
--   Display the difficulty as well.

Delimiter //
Create Procedure TopN(IN P_TopN Int)
Begin

Select Dev_ID,Difficulty,Headshots_Count
From
	 (
	 Select Dev_ID,Difficulty,Headshots_Count,Row_Number() Over(Partition by Dev_ID Order by Headshots_Count) as Rankk
	 From level_details
     ) as Project
Where Rankk<=P_TopN;

End //

Call TopN(3);

#17) Create a function to return sum of Score for a given player_id.

Delimiter //
Create Function Get_Score(F_ID Int)
Returns Int
Deterministic
Begin

Return 
	(Select Sum(Score) From level_details Where P_ID=F_ID);
	
End //

Select Get_Score(300) as score;


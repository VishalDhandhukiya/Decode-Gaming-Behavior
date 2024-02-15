# Decode-Gaming-Behavior


- Dataset Overview: The dataset is about a game and has two tables: one for "Player Details" and another for "Level Details"

- Game Structure: Players engage in a game with three levels (L0, L1, and L2), each featuring three difficulty levels (Low, Medium, High). The objective is to defeat opponents using guns or physical combat across multiple stages in each difficulty level. Players can access L1 using a system-generated L1_code, and only those who have played Level 1 can proceed to Level 2 with a corresponding L2_code. All players have default access to L0. Player authentication is based on a Dev_ID, and extra lives can be earned at each stage within a level.


Key Highlights:

- Window Functions: Implemented window functions such as rank and row_number to effectively organize and rank data within specified partitions.

- Subqueries: Employed subqueries with Where Clauses to efficiently filter and extract specific information. Additionally, utilized subqueries with From Clauses to handle various query requirements.

- Stored Procedure: Developed a stored procedure to identify the "top n" "headshots_count" based on each "Dev_ID" and ranked them in increasing order using the Row_Number function.

- Function: Created a function that returns the sum of the Score for a given "player_id", providing a concise way to retrieve cumulative score information

select w1.id
from Weather w1
join Weather w2
where w1.temperature > w2.temperature 
and DATEDIFF(w1.RecordDate, w2.RecordDate)=1
--leetcode

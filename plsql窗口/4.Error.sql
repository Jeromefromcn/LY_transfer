
SELECT t.errormsg,t.* FROM transfer_errors t ORDER BY t.errorno DESC;
/*
--shanchu 删除
DELETE FROM transfer_errors;
commit;
*/
-- test
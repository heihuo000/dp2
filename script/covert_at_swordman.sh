select_char_sql="select * from taiwan_cain.charac_info where charac_no=$1 and lev=1"
covert_char_sql="update taiwan_cain.charac_info set job=10 where charac_no=$1 and lev=1"
echo "$covert_char_sql" >> /dp2/script/covert_char_sql.log
mysql -ugame -p'uu5!^%jg' -e "$covert_char_sql"


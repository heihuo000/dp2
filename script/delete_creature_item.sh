select_creature_item_sql="select  * from taiwan_cain_2nd.creature_items where charac_no=$1 and slot=$2 and it_id=$3"
delete_creature_item_sql="delete from taiwan_cain_2nd.creature_items where charac_no=$1 and slot=$2 and it_id=$3"
echo "$delete_creature_item_sql" >> /dp2/script/delete_creature_item_sql.log
mysql -ugame -p'uu5!^%jg' -e "$delete_creature_item_sql"

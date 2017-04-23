#!/bin/sh

work_dir=/tmp/`date +%Y%m%d`_TSS_04
list_file=${work_dir}/dblog_work.lst
del_list_file=${work_dir}/del_log.lst
node_name=`uname -n`

if [ ! -e ${work_dir} ]
then
   echo "Error: WorkDir not found ${work_dir}"
   exit 1
fi

if [ ! -e $list_file ]
then
  echo "Error: not found ${list_file}"
  exit 1
fi

function get_file_num() {
  local base_dir=$1
  local log_file=$2
  local file_num=0
  if ls ${base_dir}/${log_file} > /dev/null 2>&1
  then
    file_num=`ls -f ${base_dir}/${log_file} | wc -l`
  fi
  echo ${file_num}
  return
}  

function delete_files() {
  local log_file=$1
  echo "--- ファイル削除開始 ---"
  local count=0
  for line in `cat ${log_file}`
  do
    if [[ "$line" =~ ^"${work_dir}" ]]
    then 
      rm -f ${line}
    else 
      echo "Error: $line is hoge!"
    fi
    count=`expr ${count} + 1`
    if [ ${count} -gt 99 ]
    then
      echo "--- 5秒待機 ---"
      sleep 5
      count=0
      echo "--- ファイル削除中 --"
    fi
  done
  echo "--- ファイル削除終了 ---"
  echo ""
}

function create_del_log_list() {
  local list_file=$1
  for lst in `cat ${list_file}`
  do
    local back_dir=`echo $lst | cut -d"," -f 1 | sed -e "s/_nodename_/${node_name}/g"`
    local back_dir="${work_dir}/${back_dir}"
    local log_file=`echo $lst | cut -d"," -f 2` 
    local file_num=`get_file_num ${back_dir} ${log_file}`

    if [ ! -e ${del_list_file} ]
    then 
      touch ${del_list_file}
    fi

    if [ ${file_num} -ne 0 ]
    then
      ls -f ${back_dir}/${log_file} >> ${del_list_file} 
      echo "${back_dir}/${log_file}: ${file_num}"
    fi 
 done
}

echo "### ファイル削除 ###"
create_del_log_list ${list_file}
del_log_num=`cat ${del_list_file} | wc -l`
if [ $del_log_num -ne 0 ]
then 
  echo ""
  echo "削除しますか? [y/n]"
  read yn
  if [ "${yn}" == "y" ] 
  then 
    delete_files ${del_list_file}
  fi
else
  echo "削除対象のファイルが存在しません。処理を終了します。"
fi

mv ${del_list_file} ${del_list_file}_`date +%Y%m%d-%H%M%S`


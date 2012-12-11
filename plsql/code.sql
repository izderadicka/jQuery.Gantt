c_epoch_tz CONSTANT timestamp with time zone := to_timestamp_tz('1970-01-01 0:00', 'YYYY-MM-DD TZH:TZM');
c_epoch CONSTANT timestamp := to_timestamp('1970-01-01', 'YYYY-MM-DD');

FUNCTION time_ms_tz(time_in timestamp with time zone) RETURN int  AS
diff interval day(9) to second(9) := time_in at time zone 'GMT' - c_epoch_tz;
BEGIN
RETURN 1000* (extract(day from diff) * 86400
+ extract(hour from diff) * 3600
+ extract(minute from diff) * 60
+ extract(second from diff))
;
END;

FUNCTION time_ms(time_in timestamp with time zone) RETURN int  AS
diff interval day(9) to second(9) := time_in - c_epoch;
BEGIN
RETURN 1000 *(extract(day from diff) * 86400
+ extract(hour from diff) * 3600
+ extract(minute from diff) * 60
+ extract(second from diff))  
;
END;

FUNCTION serialize_timestamp(time_in timestamp with time zone) return varchar as
l_time_str varchar(50);
begin
l_time_str := '/Date('||to_char(time_ms_tz(time_in))||')/';
return l_time_str;
end;

FUNCTION gantt_render (
   p_region              IN APEX_PLUGIN.T_REGION,
   p_plugin              IN APEX_PLUGIN.T_PLUGIN,
   p_is_printer_friendly IN BOOLEAN
)

   RETURN APEX_PLUGIN.T_REGION_RENDER_RESULT
   
IS

   l_retval         APEX_PLUGIN.T_REGION_RENDER_RESULT;
   l_onload_code    VARCHAR2(4000);
   l_from_date_item apex_application_page_regions.attribute_01%type := p_region.attribute_01;
   l_to_date_item apex_application_page_regions.attribute_02%type := p_region.attribute_02;
   l_additional_params  apex_application_page_regions.attribute_03%type := p_region.attribute_03;
   l_date_format   apex_appl_plugins.attribute_01%TYPE := p_plugin.attribute_01;
   
   
   l_crlf           CHAR(2) := CHR(13)||CHR(10);
   
BEGIN

   IF apex_application.g_debug 
   THEN
      apex_plugin_util.debug_region (
         p_plugin => p_plugin,
         p_region => p_region
      );
   END IF;

   sys.htp.p(
      '<div id="' || p_region.static_id || '_GANTT" class="gantt"></div>'
   );

   apex_javascript.add_library(
      p_name      => 'gantt',
      --p_directory => 'http://localhost/gantt/js/',
      p_directory => p_plugin.file_prefix,
      p_version   => NULL
   );

   apex_javascript.add_library (
      p_name      => 'jquery.fn.gantt.min',
      --p_directory => 'http://localhost/gantt/js/',
      p_directory=> p_plugin.file_prefix,
      p_version   => NULL
   );
   
    apex_javascript.add_library (
      p_name      => 'date-lib.min',
      --p_directory => 'http://localhost/gantt/js/',
      p_directory => p_plugin.file_prefix,
      p_version   => NULL
   );

  
  apex_css.add_file(
      p_name      => 'style',
      --p_directory => 'http://localhost/gantt/css/',
      p_directory => p_plugin.file_prefix,
      p_version   => NULL
   );
   
   if l_additional_params is null or length(l_additional_params) < 2 then
   l_additional_params:='{}';
   end if;

   l_onload_code := 'apexGantt.create("' || p_region.static_id || '", "' 
                                  || apex_plugin.get_ajax_identifier() || '", "' 
                                  || l_from_date_item || '", "' 
                                  || l_to_date_item|| '", "' 
                                  || l_date_format
                                  || '", '|| l_additional_params || ');';
     

      
   apex_javascript.add_onload_code (
      p_code => l_onload_code
   );
        
   RETURN l_retval;
    
END gantt_render;

FUNCTION gantt_ajax (
   p_region IN APEX_PLUGIN.T_REGION,
   p_plugin IN APEX_PLUGIN.T_PLUGIN
)

   RETURN APEX_PLUGIN.T_REGION_AJAX_RESULT

IS

  l_retval APEX_PLUGIN.T_REGION_AJAX_RESULT;
  l_column_value_list APEX_PLUGIN_UTIL.T_COLUMN_VALUE_LIST2;
   l_data_type_list    wwv_flow_global.vc_arr2;
  
--  SELECT ROW_NAME, ROW_DESC, ID as TASK_ID, TASK_FROM, TASK_TO, TASK_LABEL, TASK_DESCRIPTION, TASK_TYPE
  
  l_row_id     VARCHAR2(50); 
  l_row_name   VARCHAR2(2000);
  l_row_desc   VARCHAR(32767);
  l_task_id    VARCHAR(200);
  l_task_from  VARCHAR2(50);
  l_task_to    VARCHAR2(50);
  l_task_label VARCHAR2(2000);
  l_task_desc  VARCHAR2(32767);
  l_task_type  VARCHAR2(200);
  l_crlf       CHAR(2) := CHR(13)||CHR(10);
  l_prev_name  VARCHAR2(2000) := NULL;
  l_prev_desc  VARCHAR(32767) :=NULL; 
  
  l_length     number;

BEGIN
   
l_data_type_list(1):=apex_plugin_util.c_data_type_number;
l_data_type_list(2):=apex_plugin_util.c_data_type_varchar2;
l_data_type_list(3):=apex_plugin_util.c_data_type_varchar2;
l_data_type_list(4):=apex_plugin_util.c_data_type_number;
l_data_type_list(5):=apex_plugin_util.c_data_type_timestamp_ltz;
l_data_type_list(6):=apex_plugin_util.c_data_type_timestamp_ltz;
l_data_type_list(7):=apex_plugin_util.c_data_type_varchar2;
l_data_type_list(8):=apex_plugin_util.c_data_type_varchar2;
l_data_type_list(9):=apex_plugin_util.c_data_type_varchar2;


   l_column_value_list := apex_plugin_util.get_data2(
      p_sql_statement  => p_region.source, 
      p_min_columns    => 9, 
      p_max_columns    => 9, 
      p_data_type_list => l_data_type_list,
      p_component_name => p_region.name
   );   

   apex_plugin_util.print_json_http_header;
   
   sys.htp.p('[');
   
  
   l_length := l_column_value_list(1).value_list.count;
   FOR x IN 1 .. l_length
   LOOP
      l_row_id:=  to_char(l_column_value_list(1).value_list(x).number_value);
      l_row_name := sys.htf.escape_sc(l_column_value_list(2).value_list(x).varchar2_value);
      l_row_desc := sys.htf.escape_sc(l_column_value_list(3).value_list(x).varchar2_value);
      l_task_id:=  to_char(l_column_value_list(4).value_list(x).number_value);
      l_task_from :=  serialize_timestamp(l_column_value_list(5).value_list(x).timestamp_ltz_value);
      l_task_to := serialize_timestamp(l_column_value_list(6).value_list(x).timestamp_ltz_value);
      l_task_label := sys.htf.escape_sc(l_column_value_list(7).value_list(x).varchar2_value);
      l_task_desc :=l_column_value_list(8).value_list(x).varchar2_value;
      l_task_type := sys.htf.escape_sc(l_column_value_list(9).value_list(x).varchar2_value);
  
      if l_row_name!=l_prev_name or l_row_desc != l_prev_desc or l_prev_name is null then  
        if l_prev_name is not null then 
          htp.p( ']},'); 
        end if;
         
        
          sys.htp.p( '{'
          ||apex_javascript.add_attribute('id', l_row_id, TRUE, TRUE)
         || apex_javascript.add_attribute('name', case when l_row_name!=l_prev_name or  l_prev_name is  null then 
                l_row_name else ' ' end, TRUE, TRUE)
         || apex_javascript.add_attribute('desc', l_row_desc, TRUE, TRUE)
         || '"values": [');
        l_prev_name:=l_row_name;
        l_prev_desc:= l_row_desc;
      else  if x>1 then 
        htp.p(','); 
        end if;   
      end if;
      sys.htp.p( '{'
      || apex_javascript.add_attribute('from', l_task_from, TRUE, TRUE)
      || apex_javascript.add_attribute('to', l_task_to, TRUE, TRUE)
      || apex_javascript.add_attribute('label', l_task_label, TRUE, TRUE)
      || apex_javascript.add_attribute('desc', l_task_desc, TRUE, TRUE)
      || apex_javascript.add_attribute('customClass', l_task_type, TRUE, TRUE)
      || '"dataObj": {' || apex_javascript.add_attribute('id',l_task_id, True, FALSE) || '}'
      || '}');
         
        
       
         
     
   END LOOP;
   if l_length>0 then
   htp.p(']}');
   end if;
   htp.p(']');

   RETURN l_retval;

END gantt_ajax;
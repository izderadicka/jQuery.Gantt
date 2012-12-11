var apexGantt = {};

(function($) {
	apexGantt.create = (function(id, ajaxIdentifier, pageItemFrom, pageItemTo, dateFormat, options) {
		var that = {},
				main=this,
				gantt = $('#' + id + '_GANTT'), 
				region = $('#' + id);
		options = options || {};
		dateFormat=dateFormat || 'd-MMM-y';
		main[id] = that

		options = $.extend({
			navigate : "scroll",
			scale : "hours",
			maxScale : "days",
			minScale : "hours",
			itemsPerPage : 100
		}, options, {
			onItemClick : function(data) {
				//alert("Item clicked - show some details" + data);
				region.trigger('taskclicked', data)
			},
			onAddClick : function(dt, rowId, date) {
				date=new Date(parseInt(date));
				//alert("Empty space clicked - at row!" +rowId);
				region.trigger('addnewtask', {date:date, id:rowId})
			},
			onRender : function() {
				if (window.console && typeof console.log === "function") {
					console.log("chart rendered");
				}
			}
		});
		
		
		main.parse_date=function(dateStr, format) {
			if (!format) format='d-MMM-y';
			
			return Date.parseString(dateStr, format)
		}

		that.reloadData = function() {

			region.trigger('apexbeforerefresh');

			$.ajax({
				type : 'POST',
				url : 'wwv_flow.show',
				data : {
					p_flow_id : $v('pFlowId'),
					p_flow_step_id : $v('pFlowStepId'),
					p_instance : $v('pInstance'),
					p_request : 'PLUGIN=' + ajaxIdentifier,
					p_arg_names : [pageItemFrom, pageItemTo],
					p_arg_values : [$v(pageItemFrom), $v(pageItemTo)]
				},
				dataType : 'json',
				success : function(data) {
					console.log('loaded data of type '+ typeof data);
					console.log('Date range is '+$v(pageItemFrom)+ ' - '+ $v(pageItemTo));
					options.source=data;
					options.startDate=main.parse_date($v(pageItemFrom), dateFormat);
					options.endDate=main.parse_date($v(pageItemTo), dateFormat)
					gantt.gantt(options);
					region.trigger('apexafterrefresh');
				},
				error: function(r, error, ex) {
					alert(error+'\n'+ex);
				}
			});
		}

		that.reloadData()
		return that
	});
})(apex.jQuery)

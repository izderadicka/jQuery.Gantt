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
			navigate : "buttons_limited",
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
		
		var safeSplit=function(str) {
			var arr=str.split(',')
			for (var i=0;i<arr.length;i+=1) {
				arr[i]=arr[i].replace(/^\s+|\s+$/g, '')
			}
			return arr;
		}

		that.reloadData = function(additionalItemsToSubmit) {

			region.trigger('apexbeforerefresh');
			var itemsToSubmit=[pageItemFrom, pageItemTo];
			if (additionalItemsToSubmit) {
				itemsToSubmit.push.apply(itemsToSubmit,safeSplit(additionalItemsToSubmit));
			}
			if (options.itemsToSubmit) {
				itemsToSubmit.push.apply(itemsToSubmit,safeSplit(options.itemsToSubmit));
			}
			var valsToSubmit=[];
			for (var i=0; i<itemsToSubmit.length;i+=1) {
				valsToSubmit.push($v(itemsToSubmit[i]));
			}
			$.ajax({
				type : 'POST',
				url : 'wwv_flow.show',
				data : {
					p_flow_id : $v('pFlowId'),
					p_flow_step_id : $v('pFlowStepId'),
					p_instance : $v('pInstance'),
					p_request : 'PLUGIN=' + ajaxIdentifier,
					p_arg_names : itemsToSubmit,
					p_arg_values : valsToSubmit
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
    region.on('apexrefresh', function(event) {that.reloadData()});
		that.reloadData()
		return that
	});
})(apex.jQuery)

package {
	/* 
	 * 动漫条目类
	 * @author Kevin
	 */
	public class ComicData {
		// 一周的毫秒数
		private static const WEEK_TIME:Number = 604800000;
		// 一天的毫秒数
		private static const DAY_TIME:Number = 86400000;
		
		// 更新日对应常量
		private static const INT_SUN:int = 0;
		private static const INT_MON:int = 1;
		private static const INT_TUE:int = 2;
		private static const INT_WED:int = 3;
		private static const INT_THU:int = 4;
		private static const INT_FRI:int = 5;
		private static const INT_SAT:int = 6;
		private static const INT_TERMINATED:int = -1;
		
		// 标题
		private var _title:String;
		// 类型
		private var kind:String;
		// 已观看
		private var now:uint;
		// 总集数
		private var total:uint;
		// 更新日
		private var update:int;
		// 链接
		private var url:String;
		// 最近更新日期
		private var date:Date;
		
		public function ComicData(title:String = "未命名", comicType:String = "其他", seriesNow:uint = 0, seriesTotal:uint = 0, 
								updateDay:int = -1, watchURL:String = "", lastDate:Date = null)
		{
			if (lastDate == null) lastDate = ComicData.getLatestDate(updateDay);
			init(title, comicType, seriesNow, seriesTotal, updateDay, watchURL, lastDate);
		}
		
		private function init(_title2:String, _kind2:String, _now2:uint, _total2:uint, _update2:int, _url2:String, _date2:Date):void
		{
			this._title = _title2;
			this.kind = _kind2;
			this.now = _now2;
			this.total = _total2;
			this.update = _update2;
			this.url = _url2;
			this.date = _date2;
		}
		
		// 更新集数
		public function updateDate(nowDate:Date):Boolean
		{
			if (update == INT_TERMINATED) return false;
			var offset:int = int((nowDate.time - date.time) / WEEK_TIME);
			if (offset > 0) {
				date.time += WEEK_TIME * offset;
				total += offset;
				return true;
			} else {
				return false;
			}
		}
		
		// 取得最后更新日
		public static function getLatestDate(day:int):Date
		{
			var latestDate:Date = new Date();
			if (day < 0 || day > 6) return new Date();
			// 取得日期
			latestDate.time -= (day <= latestDate.day) ? (latestDate.day - day) * DAY_TIME : (latestDate.day + 7 - day) * DAY_TIME;
			// 将时间置为0点
			latestDate.hours = latestDate.minutes = latestDate.seconds = 0;
			return latestDate;
		}
		
		// 标题
		public function set title(value:String):void
		{
			_title = value;
		}
		
		// 类型
		public function set comicType(value:String):void
		{
			kind = value;
		}
		
		// 链接
		public function set watchURL(value:String):void
		{
			url = value;
		}
		
		// 已观看集数
		public function set seriesNow(value:uint):void
		{
			now = value;
		}
		
		// 总集数
		public function set seriesTotal(value:uint):void
		{
			total = value;
		}
		
		// 更新日
		public function set updateDay(value:int):void
		{
			update = value;
		}
		
		// 上次更新时间
		public function set lastUpdate(value:Date):void
		{
			date = value;
		}
		
		public function get title():String
		{
			return _title;
		}
		
		public function get comicType():String
		{
			return kind;
		}
		
		public function get watchURL():String
		{
			return url;
		}
		
		public function get seriesNow():uint
		{
			return now;
		}
		
		public function get seriesTotal():uint
		{
			return total;
		}
		
		public function get lastUpdate():Date
		{
			return date;
		}
		
		public function get updateDay():int
		{
			return update;
		}
		
		public function get updateDayString():String
		{
			var str:String = "每周";
			switch(update) {
				case INT_SUN:
					str += "日";
					break;
				case INT_MON:
					str += "一";
					break;
				case INT_TUE:
					str += "二";
					break;
				case INT_WED:
					str += "三";
					break;
				case INT_THU:
					str += "四";
					break;
				case INT_FRI:
					str += "五";
					break;
				case INT_SAT:
					str += "六";
					break;
				case INT_TERMINATED:
					str = "已完结";
					return str;
					break;
				default:
					str = "无";
			}
			str += "更新";
			return str;
		}
	}
}
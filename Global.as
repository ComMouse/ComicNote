package
{
	import flash.display.MovieClip;
	import flash.net.SharedObject;
	import flash.net.FileReference;
	import flash.net.FileFilter;
	import flash.system.System;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.display.Sprite;
	import lib.*;

	/**
	 * 动漫备忘录主程序
	 * @author Kevin
	 */
	public final class Global
	{
		// 动漫板栏高
		protected static const BLOCK_HEIGHT:uint = 86;
		// 版本
		protected static const VERSION:String = "1.35";
		// 作者
		protected static const AUTHOR:String = "Kevin Studio";
		
		// 以下为文件操作结果常量，用于导入/导出操作
		public static const DATA_SUCCESS:int = 0;
		public static const DATA_FAILED:int = 1;
		
		// 当前条目
		public static var currentData:ComicData;
		// 当前栏
		public static var currentBlock:ComicBlock;
		// 展示板
		public static var blockBox:ScrollArea;
		// 数据列表
		public static var dataList:Vector.<ComicData>;
		// 栏板列表
		private static var blockList:Vector.<ComicBlock>;
		// 主场景引用
		public static var scene:MovieClip;
		// 文件操作引用
		private static var fileRef:FileReference;
		
		public function Global()
		{
			// 由于该类为静态类，禁止初始化构造
			throw new Error("The Global class can't be instanced!");
		}
		
		public static function init()
		{
			Global.scene["ver_txt"].text = "Version " + VERSION + " by " + AUTHOR;
			var contentBg:Sprite = new Sprite();
			blockBox = new ScrollArea(540, BLOCK_HEIGHT*3, contentBg);
			blockBox.x = 16;
			blockBox.y = 80;
			Global.scene.contents.addChild(blockBox);
			
			dataList = new Vector.<ComicData>();
			blockList = new Vector.<ComicBlock>();
			
			// 载入数据
			var so:SharedObject = SharedObject.getLocal("kevinstudio_comicnote", "/");
			// 初始化数据
			if (!(so.data.hasOwnProperty("inited") && so.data.inited == true)) {
				so.data.inited = true;
				so.data.list = new Vector.<Object>();
				so.flush();
			}
			// 读取数据
			var list:Vector.<Object> = so.data.list;
			for (var i:uint = 0; i < list.length; i++) {
				if (list[i] != null) {
					// 由于ShardObject保存机制会把Vector转为Vector.<Object>，把非系统顶级类转为Object，需要
					// 重新构造ComicData对象以确保使用
					if (list[i].hasOwnProperty("lastUpdate")){
						dataList.push(new ComicData(list[i].title, list[i].comicType, list[i].seriesNow, list[i].seriesTotal, 
												list[i].updateDay, list[i].watchURL, list[i].lastUpdate));
					} else {
						dataList.push(new ComicData(list[i].title, list[i].comicType, list[i].seriesNow, list[i].seriesTotal, 
												list[i].updateDay, list[i].watchURL));
					}
				}
			}
			// 更新集数
			var nowDate:Date = new Date();
			for (i = 0; i < dataList.length; i++) {
				dataList[i].updateDate(nowDate);
				var block:ComicBlock = new ComicBlock();
				block.name = "block" + (i + 1).toString();
				blockBox.content.addChild(block);
				block.setData(dataList[i]);
				blockList.push(block);
			}
			saveData();
			
			updatePos();
		}
		
		// 取得栏板对应条目
		public static function getData(block:ComicBlock):ComicData
		{
			if (block == null) {
				return null;
			}
			var index:int = -1;
			for (var i:uint = 0; i < blockList.length; i++) {
				if (blockList[i] == block) {
					index = i;
					break;
				}
			}
			if (index == -1) return null;
			return dataList[index];
		}
		
		// 添加条目
		public static function addData(data:ComicData, refreshNow:Boolean = true):void
		{
			if (data == null) return;
			dataList.push(data);
			var block:ComicBlock = new ComicBlock();
			block.name = "block" + dataList.length.toString();
			blockBox.content.addChild(block);
			block.setData(data);
			blockList.push(block);
			
			if (refreshNow){
				saveData();
				updatePos();
			}
		}
		
		// 移除条目
		public static function removeData(data:ComicData, forced:Boolean = false):void
		{
			if (data == null && !forced) {
				return;
			}
			var index:int = -1;
			for (var i:uint = 0; i < dataList.length; i++) {
				if (dataList[i] == data) {
					index = i;
					break;
				}
			}
			if (index == -1) return;
			dataList.splice(index, 1);
			if (data != null) {
				var block:ComicBlock = blockList[index];
				blockBox.content.removeChild(block);
			}
			blockList.splice(index, 1);
			saveData();
			updatePos();
		}
		
		// 清空条目
		public static function clearData():void
		{
			while (dataList.length != 0) {
				removeData(dataList[0], true);
			}
		}
		
		// 保存数据
		public static function saveData():void
		{
			var so:SharedObject = SharedObject.getLocal("kevinstudio_comicnote", "/");
			so.data.list = dataList;
			so.flush();
		}
		
		// 导出文件
		// 参数中callFun指传递结果的调用函数，参数只有1个int
		public static function saveFile(callFun:Function = null):void
		{
			// 转为 UTF-8 编码
			System.useCodePage = false;
			
			var xml:XML = <data></data>;
			var tempData:ComicData = null;
			var tempNode:XML = null;
			for (var i:uint = 0; i < dataList.length; i++) {
				tempData = dataList[i];
				tempNode = <comic></comic>;
				tempNode.title = tempData.title;
				tempNode.comicType = tempData.comicType;
				tempNode.seriesNow = tempData.seriesNow.toString();
				tempNode.seriesTotal = tempData.seriesTotal.toString();
				tempNode.updateDay = tempData.updateDay.toString();
				tempNode.watchURL = tempData.watchURL;
				// 转为 UTC 时间存储
				if (tempData.updateDay != -1) tempNode.lastUpdate = tempData.lastUpdate.toUTCString();
				xml.appendChild(tempNode);
			}
			
			// 保存并监听事件
			fileRef = new FileReference();
			// IO 错误的情况
			fileRef.addEventListener(IOErrorEvent.IO_ERROR, function (event:IOErrorEvent)
			{
				fileRef = null;
				if (callFun == null) return;
				try {
					callFun(DATA_FAILED);
				} catch (error : ArgumentError) { }
			});
			// 成功的情况
			fileRef.addEventListener(Event.COMPLETE, function (event:Event)
			{
				fileRef = null;
				if (callFun == null) return;
				try {
					callFun(DATA_SUCCESS);
				} catch (error : ArgumentError) { }
			});
			// 在System.useCodePage 为 false 情况下输出UNIX模式，换行为\n
			try {
				fileRef.save("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" + xml.toXMLString(), "My Comic Backup.xml");
			} catch (error:*) {
				if (callFun == null) return;
				try {
					callFun(DATA_FAILED);
				} catch (error : ArgumentError) { }
			}
		}
		
		// 导入文件（参数含义同上）
		public static function loadFile(callFun:Function = null):void
		{
			// 避免使用局部变量，以防GC自动回收fileRef
			fileRef = new FileReference();
			// 添加监听器
			fileRef.addEventListener(Event.SELECT, selectFileHandler);
			// 成功的情况
			fileRef.addEventListener(Event.COMPLETE, function (event:Event) 
			{
				if (loadFileHandler(event)) {
					if (callFun == null) return;
					try {
						callFun(DATA_SUCCESS);
					} catch (error : ArgumentError) { }
				} else {
					if (callFun == null) return;
					try {
						callFun(DATA_FAILED);
					} catch (error : ArgumentError) { }
				}
			});
			// IO 错误的情况
			fileRef.addEventListener(IOErrorEvent.IO_ERROR, function (event:IOErrorEvent)
			{
				errorFileHandler(event);
				if (callFun == null) return;
				try {
					callFun(DATA_FAILED);
				} catch (error : ArgumentError) { }
			});
			// 浏览路径
			fileRef.browse([new FileFilter("数据文件 (*.xml)", "*.xml"), new FileFilter("所有文件 (*.*)", "*.*")]);
		}
		
		// 选择文件处理
		private static function selectFileHandler(event:Event):void
		{
			if (fileRef == null) return;
			try {
				fileRef.load();
			} catch (e:Error) {
				trace("Load Error: " + e.toString());
			}
		}
		
		// 读取文件处理（返回Boolean指示是否成功）
		private static function loadFileHandler(event:Event):Boolean
		{
			if (fileRef == null) return false;
			var addCount:int = 0;
			try {
				XML.ignoreWhitespace = true;
				var xml:XML = new XML(fileRef.data);
				var len:uint = xml.comic.length();
				// 此处勿用XMLList，XML为根节点单个的，XMLList为根节点多个的，
				// 此处<comic></comic>段仅需单根节点即可
				var singleItem:XML = null;
				var singleData:ComicData = null;
				var block:ComicBlock = null;
				for (var i:uint = 0; i < len; i++){
					singleItem = xml.comic[i];
					if (singleItem.title == null || singleItem.title == "") continue;
					// updateDay可以为-1，别用uint！！
					if (singleItem.hasOwnProperty("lastUpdate")) {
						singleData = new ComicData(singleItem.title, singleItem.comicType, uint(singleItem.seriesNow), 
											   	uint(singleItem.seriesTotal), int(singleItem.updateDay), singleItem.watchURL, 
											  	new Date(Date.parse(singleItem.lastUpdate)));
					} else {
						singleData = new ComicData(singleItem.title, singleItem.comicType, uint(singleItem.seriesNow), 
											   	uint(singleItem.seriesTotal), int(singleItem.updateDay), singleItem.watchURL);
					}
					addData(singleData, false);
					addCount++;
				}
			} catch (err:Error) {
				trace("Load Error: " + err.toString());
				saveData();
				updatePos();
				return false;
			}
			saveData();
			updatePos();
			return (addCount != 0) ? true : false;
		}
		
		// 错误处理
		private static function errorFileHandler(event:IOErrorEvent):void
		{
			trace("Load Error: " + event.toString());
		}
		
		// 更新区域坐标
		private static function updatePos():void
		{
			// 更新栏板坐标及背景色
			var block:ComicBlock;
			for (var i:uint = 0; i < blockList.length; i++) {
				block = blockList[i];
				block.x = 0;
				block.y = i * BLOCK_HEIGHT;
				block.changeBg((i+1) % 2);
			}
			// 修正滚动条内容区高度
			blockBox.updateArea(blockList.length * BLOCK_HEIGHT);
		}
	}
}
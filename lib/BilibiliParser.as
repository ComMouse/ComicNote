package lib
{
	import com.probertson.utils.GZIPBytesEncoder;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.events.IEventDispatcher;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.events.ErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.utils.ByteArray;

	public class BilibiliParser extends HTMLParser implements IEventDispatcher
	{
		private static const SPID_REGEXP:RegExp = /spid = (\d+);/;
		private static const EPID_REGEXP:RegExp = /new bbBangumiSp\(aid, spid, (\d+)/;
		private static const JSON_URL:String = "http://www.bilibili.com/index/bangumi/{0}-s{1}.json";

		private static const SPID_IGNORE_CNT:int = 1;
		private static const EPID_IGNORE_CNT:int = 0;

		public function BilibiliParser(watchURL:String = null)
		{
			super(watchURL, true);
		}

		override final protected function parseHtml(bytes:ByteArray):void
		{
			var decoder:GZIPBytesEncoder = new GZIPBytesEncoder();
			bytes = decoder.uncompressToByteArray(bytes);
			bytes.position = 0;
			var htmlStr:String = bytes.readMultiByte(bytes.length, textEncoding);

			var i:int;
			for (i = 0; i < SPID_IGNORE_CNT; i++) {
				htmlStr = htmlStr.replace(SPID_REGEXP,"");
			}

			for (i = 0; i < EPID_IGNORE_CNT; i++) {
				htmlStr = htmlStr.replace(EPID_REGEXP,"");
			}

			var avid:int = int(htmlStr.match(SPID_REGEXP)[1]);
			var epid:int = int(htmlStr.match(EPID_REGEXP)[1]);

			loader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, jsonLoadedHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			loader.load(new URLRequest(JSON_URL.replace("{0}", avid).replace("{1}", epid)));
		}

		private function parseJSON(bytes:ByteArray):void
		{
			var decoder:GZIPBytesEncoder = new GZIPBytesEncoder();
			bytes = decoder.uncompressToByteArray(bytes);
			bytes.position = 0;
			var jsonStr:String = bytes.readMultiByte(bytes.length, textEncoding);
			var eposideArray:Array = JSON.parse(jsonStr) as Array;

			var maxEposide:int = -1;
			for each (var item:Object in eposideArray) {
				if (int(item["episode"]) > maxEposide) {
					maxEposide = int(item["episode"]);
				}
			}
			//trace(maxEposide);
			
			dispatchParseResult(maxEposide);
		}

		private function jsonLoadedHandler(event:Event):void
		{
			removeAllListeners();

			try {
				var tempData:ByteArray = loader.data as ByteArray;
				parseJSON(tempData);
			} catch (error:Error) {
				dispatcher.dispatchEvent(new ErrorEvent("Parsing Error!"));
			}
		}
		
		private function errorHandler(event:ErrorEvent):void
		{
			removeAllListeners();
			dispatcher.dispatchEvent(event);
		}
		
		override protected function removeAllListeners():void
		{
			if (loader == null) {
				return;
			}
			
			super.removeAllListeners();
			loader.removeEventListener(Event.COMPLETE, jsonLoadedHandler);
		}
	}
}
package 
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

	public class HTMLParser
	{
		private static const EPID_REGEXP:RegExp = /更新至(\d+)集/;

		private static const EPID_IGNORE_CNT:int = 0;

		protected var url:String;
		protected var loader:URLLoader;
		protected var dispatcher:EventDispatcher;
		protected var maxEposide:int;
		protected var textEncoding:String;
		protected var gzip:Boolean;

		public function HTMLParser(watchURL:String = null, gzipped:Boolean = false, encoding:String = "utf-8")
		{
			url = watchURL;
			gzip = gzipped;
			textEncoding = encoding;
			dispatcher = new EventDispatcher();
		}

		public function parse():void
		{
			removeAllListeners();
			maxEposide = -1;

			if (url == null) {
				throw new Error("Watch URL is not set!");
				return;
			}

			loader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, htmlLoadedHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.load(new URLRequest(url));
		}

		public final function addEventListener(type:String, listener:Function, useCapture:Boolean = false, 
		 priority:int = 0, useWeakReference:Boolean = false):void
		{
			dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}

		public final function dispatchEvent(event:Event):Boolean
		{
			return dispatcher.dispatchEvent(event);
		}

		public final function hasEventListener(type:String):Boolean
		{
			return dispatcher.hasEventListener(type);
		}

		public final function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
		{
			dispatcher.removeEventListener(type, listener, useCapture);
		}

		public final function willTrigger(type:String):Boolean
		{
			return dispatcher.willTrigger(type);
		}

		protected function parseHtml(bytes:ByteArray):void
		{
			if (gzip) {
				var decoder:GZIPBytesEncoder = new GZIPBytesEncoder();
				bytes = decoder.uncompressToByteArray(bytes);
			}
			bytes.position = 0;
			var htmlStr:String = bytes.readMultiByte(bytes.length,textEncoding);

			var i:int;
			for (i = 0; i < EPID_IGNORE_CNT; i++) {
				htmlStr = htmlStr.replace(EPID_REGEXP,"");
			}

			var epid:int = int(htmlStr.match(EPID_REGEXP)[1]);

			dispatchParseResult(epid);
		}

		private function htmlLoadedHandler(event:Event):void
		{
			removeAllListeners();

			try {
				var tempData:ByteArray = loader.data as ByteArray;
				parseHtml(tempData);
			} catch (error:Error) {
				dispatcher.dispatchEvent(new ErrorEvent("Parsing Error!"));
			}
		}

		private function errorHandler(event:ErrorEvent):void
		{
			removeAllListeners();
			dispatcher.dispatchEvent(event);
		}

		protected function dispatchParseResult(result:int):void
		{
			maxEposide = result;
			dispatcher.dispatchEvent(new Event(Event.COMPLETE));
		}

		protected function removeAllListeners():void
		{
			if (loader == null) {
				return;
			}

			loader.removeEventListener(Event.COMPLETE, htmlLoadedHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		}

		public function get encoding():String
		{
			return textEncoding;
		}

		public function set encoding(encoding:String):void
		{
			textEncoding = encoding;
		}

		public function get eposide():int
		{
			return maxEposide;
		}

		public function get gzipped():Boolean
		{
			return gzip;
		}

		public function set gzipped(gzipped:Boolean):void
		{
			gzip = gzipped;
		}

		public function get watchURL():String
		{
			return url;
		}

		public function set watchURL(watchURL:String):void
		{
			url = watchURL;
		}
	}
}
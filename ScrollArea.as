package
{
	import flash.display.Sprite;
	
	/**
	 * 滚动区域类
	 * @author Kevin
	 */
	public class ScrollArea extends Sprite
	{
		// 被滚动 MC
		protected var mc:Sprite;
		// 遮罩 MC
		protected var mask_mc:Sprite;
		// 滚动条
		protected var bar:ScrollBar;
		// 当前区域高度
		protected var nowHeight:Number;
		
		public function ScrollArea(_width:Number, _height:Number, _mc:Sprite)
		{
			mc = _mc;
			mask_mc = new Sprite();
			mask_mc.graphics.beginFill(0x000000);
			mask_mc.graphics.drawRect(0, 0, _width, _height);
			mask_mc.graphics.endFill();
			bar = new ScrollBar(this);
			
			addChild(mc);
			addChild(mask_mc);
			addChild(bar);
			mc.mask = mask_mc;
		}
		
		// 更新区域高度
		public function updateArea(newHeight:Number = -1):void
		{
			if (newHeight > 0 && nowHeight != newHeight) nowHeight = newHeight;
			bar.visible = (newHeight != 0);
			bar.updateScroll();
		}
		
		// 获取被滚动对象
		public function get content():Sprite
		{
			return mc;
		}
		
		// 取得显示区域宽度
		public function get scrollWidth():Number
		{
			return mask_mc.width;
		}
		
		// 取得显示区域高度
		public function get scrollHeight():Number
		{
			return mask_mc.height;
		}
		
		// 取得滚动区域宽度
		public function get currentWidth():Number
		{
			return mc.width;	
		}
		
		// 取得显示区域高度
		public function get currentHeight():Number
		{
			return nowHeight;	
		}
	}
}
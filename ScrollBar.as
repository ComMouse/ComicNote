package
{
	import scroll.ScrollArrow;
	import scroll.ScrollBg;
	import scroll.ScrollBtn;
	import flash.display.Sprite;
	import flash.display.SimpleButton;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	/**
	 * 滚动条类
	 * @author Kevin
	 */
	public class ScrollBar extends Sprite
	{
		// 滚动宽度步长
		protected const SCROLL_STEP:Number = 21.5;
		
		// 滚动区域
		protected var area:ScrollArea;
		// 上按钮
		protected var upArrow:ScrollArrow;
		// 下按钮
		protected var downArrow:ScrollArrow;
		// 滚动条背景
		protected var bg:ScrollBg;
		// 滚动条主条
		protected var btn:ScrollBtn;
		
		// 最上方相对 Y 坐标
		protected var upY:Number = 0;
		// 最下方相对 Y 坐标
		protected var downY:Number = 0;
		// 上次记忆区域高度
		protected var lastHeight:Number = -1;
		
		public function ScrollBar(scrollArea:ScrollArea)
		{
			area = scrollArea;
			
			bg = new ScrollBg();
			upArrow = new ScrollArrow();
			downArrow = new ScrollArrow();
			downArrow.rotation = 180;
			downArrow.x = 20;
			downArrow.y = 267;
			addChild(bg);
			addChild(upArrow);
			addChild(downArrow);
			
			btn = new ScrollBtn();
			btn.y = upArrow.height;
			addChild(btn);
			
			// 取消手形
			(upArrow as SimpleButton).useHandCursor = false;
			(downArrow as SimpleButton).useHandCursor = false;
			
			// 设置滚动条位置
			this.x = scrollArea.content.x + scrollArea.scrollWidth;
			this.y = scrollArea.content.y - 5;
			upY = scrollArea.content.y + scrollArea.content.height;
			downY = scrollArea.content.y;
			
			setupListeners();
			updateScroll();
		}
		
		// 设置监听器
		protected function setupListeners():void
		{
			upArrow.addEventListener(MouseEvent.CLICK, scrollUp);
			downArrow.addEventListener(MouseEvent.CLICK, scrollDown);
			btn.addEventListener(MouseEvent.MOUSE_DOWN, scrollOn);
			Global.scene.stage.addEventListener(MouseEvent.MOUSE_WHEEL, scrollWheel);
		}
		
		// 更新滚动坐标
		public function updateScroll():void
		{
			// 在高度变更的情况下
			if (lastHeight != area.currentHeight) {
				lastHeight = area.currentHeight;
				// 获取最底部坐标
				downY = upY - lastHeight + area.scrollHeight;
				// 判断是否需要滚动条
				if (lastHeight <= area.scrollHeight) {
					btn.visible = false;
					upArrow.enabled = downArrow.enabled = false;
					downY = 0;
				} else {
					btn.visible = true;
					upArrow.enabled = downArrow.enabled = true;
				}
				// 调整坐标
				if (area.content.y < downY) {
					area.content.y = downY;
				}
			}
			// 调整滚动条位置
			btn.y = 20 + (upY - area.content.y) * (228 - btn.height) / (upY - downY);
		}
		
		// 上滚
		protected function scrollUp(event:MouseEvent = null):void
		{
			if (area.content.y + SCROLL_STEP > upY) {
				area.content.y = upY;
			} else {
				area.content.y += SCROLL_STEP;
			}
			updateScroll();
		}
		
		// 下滚
		protected function scrollDown(event:MouseEvent = null):void
		{
			if (area.content.y - SCROLL_STEP < downY) {
				area.content.y = downY;
			} else {
				area.content.y -= SCROLL_STEP;
			}
			updateScroll();
		}
		
		// 开始拖曳滚动条
		protected function scrollOn(event:MouseEvent):void
		{
			btn.startDrag(false, new Rectangle(btn.x, 20, 0, 228 - btn.height));
			stage.addEventListener(MouseEvent.MOUSE_MOVE, scrollDragHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, scrollOff);
			updateScroll();
		}
		
		// 结束拖曳滚动条
		protected function scrollOff(event:MouseEvent):void
		{
			btn.stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, scrollDragHandler);
			stage.removeEventListener(MouseEvent.MOUSE_UP, scrollOff);
			updateScroll();
		}
		
		// 拖曳更新
		protected function scrollDragHandler(event:MouseEvent):void
		{
			area.content.y = upY - (btn.y - 20) * (upY - downY) / (228 - btn.height);
		}
		
		// 鼠标滚轮处理
		protected function scrollWheel(event:MouseEvent):void
		{
			if (!btn.visible) {
				return;
			}
			if (event.delta > 0){
				scrollUp();
			} else {
				scrollDown();
			}
		}
	}
}
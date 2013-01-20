/*******************************************************************
* ItemForSale.as
* Copyright (C) 2006-2010 Midnight Coders, Inc.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
* OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
* WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
********************************************************************/

package HttpService.TransferModel.vo
{
  import flash.utils.ByteArray;
  import mx.collections.ArrayCollection;

	[Bindable]
	[RemoteClass(alias="HttpService.TransferModel.ItemForSale")]
	public class ItemForSale
	{
		public function ItemForSale(){}
	
		public var item_id:String;
		public var title:String;
		public var description:String;
		public var image_url:String;
		public var product_url:String;
		public var price:int;
		public var data:String;
	}
}

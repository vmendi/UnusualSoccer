/*******************************************************************
* TeamPurchase.as
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
	[RemoteClass(alias="HttpService.TransferModel.TeamPurchase")]
	public class TeamPurchase
	{
		public function TeamPurchase(){}
	
		public var RemainingMatches:int;
		public var NewMatchRemainingSeconds:int;
		public var TicketPurchaseDate:Date;
		public var TicketExpiryDate:Date;
		public var TrainerPurchaseDate:Date;
		public var TrainerExpiryDate:Date;
		public var TicketExpiryDateRemainingSeconds:int;
		public var TrainerExpiryDateRemainingSeconds:int;
	}
}

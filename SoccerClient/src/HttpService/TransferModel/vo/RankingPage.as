/*******************************************************************
* RankingPage.as
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
	[RemoteClass(alias="HttpService.TransferModel.RankingPage")]
	public class RankingPage
	{
		public function RankingPage(){}
	
		public var PageIndex:int;
		public var TotalPageCount:int;
		public var Teams:ArrayCollection;
		public var RANKING_TEAMS_PER_PAGE:int;
	}
}

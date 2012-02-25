/*******************************************************************
* Team.as
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
import HttpService.TransferModel.vo.Ticket;import HttpService.TransferModel.vo.PendingTraining;
	[Bindable]
	[RemoteClass(alias="HttpService.TransferModel.Team")]
	public class Team
	{
		public function Team(){}
	
		public var Name:String;
		public var PredefinedTeamNameID:String;
		public var Formation:String;
		public var TrueSkill:int;
		public var XP:int;
		public var SkillPoints:int;
		public var Energy:int;
		public var Fitness:int;
		public var Ticket:HttpService.TransferModel.vo.Ticket;
		public var PendingTraining:HttpService.TransferModel.vo.PendingTraining;
		public var SoccerPlayers:ArrayCollection;
		public var SpecialTrainings:ArrayCollection;
	}
}

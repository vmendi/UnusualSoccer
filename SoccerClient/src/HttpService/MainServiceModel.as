/*******************************************************************
* MainServiceModel.as
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

    
    package HttpService
    {    
      import HttpService.TransferModel.vo.*;
      import mx.collections.ArrayCollection;
    
      [Bindable]
      public class MainServiceModel
      {     
        public var ChangeNameResult:String;     
        public var CreateTeamResult:Boolean;     
        public var GetExtraRewardForMatchResult:Boolean;     
        public var GetItemForSaleResult:ItemForSale;     
        public var HasTeamResult:Boolean;     
        public var HealInjuryResult:Boolean;     
        public var IsNameValidResult:String;     
        public var OnLikedResult:int;     
        public var RefreshGroupForTeamResult:CompetitionGroup;     
        public var RefreshMatchStatsForTeamResult:TeamMatchStats;     
        public var RefreshRankingPageResult:RankingPage;     
        public var RefreshSeasonEndDateRemainingSecondsResult:int;     
        public var RefreshSpecialTrainingDefinitionsResult:ArrayCollection;     
        public var RefreshTeamResult:Team;     
        public var RefreshTeamDetailsResult:TeamDetails;     
        public var RefreshTeamPurchaseInitialInfoResult:TeamPurchaseInitialInfo;     
        public var RefreshTrainingDefinitionsResult:ArrayCollection;     
        public var TargetProcessedRequestsResult:ArrayCollection;     
        public var TrainResult:PendingTraining;
      }
    }
  
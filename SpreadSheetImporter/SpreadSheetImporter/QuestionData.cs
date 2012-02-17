using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace SpreadSheetImporter
{
    class QuestionData
    {
        /// <summary>
        /// QuestionID
        /// </summary>
        private int questionId;
        public int QuestionID
        {
            get { return questionId; }
            set { questionId = value; }
        }

        /// <summary>
        /// QuestionType
        /// </summary>
        private int questionType;
        public int QuestionType
        {
            get { return questionType; }
            set { questionType = value; }
        }

        /// <summary>
        /// Question
        /// </summary>
        private string question;
        public string Question
        {
            get { return question; }
            set { question = value; }
        }

        /// <summary>
        /// Solution
        /// </summary>
        private int solution;
        public int Solution
        {
            get { return solution; }
            set { solution = value; }
        }

        /// <summary>
        /// Answer1
        /// </summary>
        private string answer1;
        public string Answer1
        {
            get { return answer1; }
            set { answer1 = value; }
        }

        /// <summary>
        /// Answer2
        /// </summary>
        private string answer2;
        public string Answer2
        {
            get { return answer2; }
            set { answer2 = value; }
        }

        /// <summary>
        /// Answer3
        /// </summary>
        private string answer3;
        public string Answer3
        {
            get { return answer3; }
            set { answer3 = value; }
        }

        /// <summary>
        /// Answer4
        /// </summary>
        private string answer4;
        public string Answer4
        {
            get { return answer4; }
            set { answer4 = value; }
        }

        /// <summary>
        /// Constructor
        /// </summary>
        public QuestionData()
        {
            QuestionID      = -1;
            QuestionType    = -1;
            Question        = string.Empty;
            Answer1         = string.Empty;
            Answer2         = string.Empty;
            Answer3         = string.Empty;
            Answer4         = string.Empty;
            Solution        = -1;

        }


    }
}

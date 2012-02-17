using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using Google.GData.Client;
using Google.GData.Extensions;
using Google.GData.Spreadsheets;
using System.Web;
using System.Collections;

namespace SpreadSheetImporter
{
    public partial class Form1 : Form
    {

        SpreadsheetsService ssService;
        SpreadsheetQuery ssquery;

        SpreadsheetFeed ssfeed;
        SpreadsheetEntry ssEntry;

        WorksheetQuery wsQuery;
        WorksheetFeed wsFeed;

        CellQuery cQuery;
        CellFeed cFeed;

        Dictionary<uint, QuestionData> QuestionList;

        public Form1()
        {
            InitializeComponent();
        }

        private void btnLogIn_Click(object sender, EventArgs e)
        {
            ssService = new SpreadsheetsService("exampleCo-exampleApp-1");
            ssService.setUserCredentials(txtUser.Text, txtPassword.Text);

            ssquery = new SpreadsheetQuery();
            ssfeed = ssService.Query(ssquery);

           string docTitles = string.Empty;

           foreach (SpreadsheetEntry entry in ssfeed.Entries)
            {
                Console.WriteLine(entry.Title.Text);
                if(docTitles == String.Empty)
                    docTitles += entry.Title.Text;
                else
                    docTitles += ("," + entry.Title.Text);                               
            }
            lstDocs.DataSource = docTitles.Split(',');

            gbImportDocument.Enabled = true;
            gbUserData.Visible = false;
            gbChangeUser.Visible = true;
        }

        private void btnImportar_Click(object sender, EventArgs e)
        {
            gbImportDocument.Enabled = false;
            gbChangeUser.Enabled = false;
            AtomLink link = ssEntry.Links.FindService(GDataSpreadsheetsNameTable.WorksheetRel, null);

            wsQuery = new WorksheetQuery(link.HRef.ToString());
            wsFeed = ssService.Query(wsQuery);

            foreach (WorksheetEntry worksheet in wsFeed.Entries)
            {
                Console.WriteLine(worksheet.Title.Text);
                ReadWorkSheet(worksheet);
            }
            ImportToBBDD(QuestionList);
            gbImportDocument.Enabled = true;
            gbChangeUser.Enabled = true;
        }


        private void lstDocs_MouseClick(object sender, MouseEventArgs e)
        {
            if(lstDocs.SelectedIndex >= 0)
                btnImportar.Enabled = true;

            foreach (SpreadsheetEntry thisEntry in ssfeed.Entries)
            {
                if (thisEntry.Title.Text == lstDocs.SelectedValue.ToString())
                {
                    ssEntry = thisEntry;
                }
            }
        }

        /// <summary>
        /// Lee un SpreadSheet de google, y lo almacena en una Lista de <paramref name="QuestionData"/>
        /// </summary>
        /// <param name="worksheet">el worksheet</param>
        private void ReadWorkSheet(WorksheetEntry worksheet)
        {
            AtomLink cellFeedLink = worksheet.Links.FindService(GDataSpreadsheetsNameTable.CellRel, null);

            cQuery = new CellQuery(cellFeedLink.HRef.ToString());
            cFeed = ssService.Query(cQuery);

            Console.WriteLine("Cells in this worksheet:");
            var a = (cQuery.MaximumRow - cQuery.MinimumRow);
            var b = wsFeed.Entries.Count;
            QuestionList = new Dictionary<uint,QuestionData>();
            foreach (CellEntry curCell in cFeed.Entries)
            {
                Console.WriteLine("Row {0}, column {1}: {2}", curCell.Cell.Row, curCell.Cell.Column, curCell.Cell.Value);
                if (curCell.Cell.Row > 1)
                {
                    if (!QuestionList.ContainsKey(curCell.Cell.Row))
                        QuestionList.Add(curCell.Cell.Row, new QuestionData());

                    switch (curCell.Cell.Column)
                    {
                        case 1:
                            QuestionList[curCell.Cell.Row].QuestionID = int.Parse(curCell.Cell.Value != null ? curCell.Cell.Value : "-1");
                            break;
                        case 2:
                            QuestionList[curCell.Cell.Row].Question = curCell.Cell.Value;
                            break;
                        case 3:
                            QuestionList[curCell.Cell.Row].Solution = int.Parse(curCell.Cell.Value);
                            break;
                        case 4:
                            QuestionList[curCell.Cell.Row].Answer1 = curCell.Cell.Value;
                            break;
                        case 5:
                            QuestionList[curCell.Cell.Row].Answer2 = curCell.Cell.Value;
                            break;
                        case 6:
                            QuestionList[curCell.Cell.Row].Answer3 = curCell.Cell.Value;
                            break;
                        case 7:
                            QuestionList[curCell.Cell.Row].Answer4 = curCell.Cell.Value;
                            break;
                        case 8:
                            QuestionList[curCell.Cell.Row].QuestionType = int.Parse(curCell.Cell.Value);
                            break;
                    }
                }
            }
        }

        /// <summary>
        /// Importa una a una a las preguntas de una lista de preguntas en la BBDD
        /// </summary>
        /// <param name="QuestionList">La lista con las preguntas</param>
        private void ImportToBBDD(Dictionary<uint, QuestionData> QuestionList)
        {
            try
            {
                //Insertamos las preguntas en la BBDD, 
                //excluyendo aquellas que tienen un ID = -1 (suelen ser líneas del SpreadSheet de google).
                foreach (QuestionData qd in QuestionList.Values)
                {
                    if (qd.QuestionID != -1)
                    {
                        InsertNewQuestionToBBDD(qd);
                    }
                }
                MessageBox.Show("La importación de las Preguntas a la BBDD se ha completado correctamente",
                                "SpreadSheet Importer",
                                MessageBoxButtons.OK,
                                MessageBoxIcon.Information);
            }
            catch (Exception e)
            {
                MessageBox.Show("Ha ocurrido un error durante el proceso de importación de las preguntas a la BBDD \n"
                                + "El mensaje de error devuelto ha sido: " + e.Message,
                                    "SpreadSheet Importer",
                                    MessageBoxButtons.OK,
                                    MessageBoxIcon.Error);
            }
                
        }

        /// <summary>
        /// Genera el objeto <paramref name="Question"/> y lo inserta en la BBDD
        /// </summary>
        /// <param name="qd">La <paramref name="Question"/></param>
        private void InsertNewQuestionToBBDD(QuestionData qd)
        {
            Question tmpQuestion = new Question();
            tmpQuestion.QuestionID = qd.QuestionID;
            tmpQuestion.Question1 = qd.Question;
            tmpQuestion.QuestionTypeID = qd.QuestionType;
            tmpQuestion.Solution = qd.Solution;
            tmpQuestion.Option1 = qd.Answer1;
            tmpQuestion.Option2 = qd.Answer2;
            tmpQuestion.Option3 = qd.Answer3;
            tmpQuestion.Option4 = qd.Answer4;

            using (DataClasses1DataContext a = new DataClasses1DataContext())
            {
                a.Questions.InsertOnSubmit(tmpQuestion);
                a.SubmitChanges();
            }
        }

        private void btnSalir_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void txtLogWithAnotherUser_Click(object sender, EventArgs e)
        {
            lstDocs.DataSource = null;
            gbImportDocument.Enabled = true;
            gbUserData.Visible = true;
            gbChangeUser.Visible = false;
        }
    }
}

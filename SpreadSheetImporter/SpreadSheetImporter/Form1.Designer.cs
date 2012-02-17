namespace SpreadSheetImporter
{
    partial class Form1
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.btnSalir = new System.Windows.Forms.Button();
            this.btnImportar = new System.Windows.Forms.Button();
            this.txtUser = new System.Windows.Forms.TextBox();
            this.txtPassword = new System.Windows.Forms.TextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.txtAppInfo = new System.Windows.Forms.TextBox();
            this.grLogin = new System.Windows.Forms.GroupBox();
            this.gbChangeUser = new System.Windows.Forms.GroupBox();
            this.txtLogWithAnotherUser = new System.Windows.Forms.Button();
            this.gbUserData = new System.Windows.Forms.GroupBox();
            this.btnLogIn = new System.Windows.Forms.Button();
            this.gbImportDocument = new System.Windows.Forms.GroupBox();
            this.lstDocs = new System.Windows.Forms.ListBox();
            this.grLogin.SuspendLayout();
            this.gbChangeUser.SuspendLayout();
            this.gbUserData.SuspendLayout();
            this.gbImportDocument.SuspendLayout();
            this.SuspendLayout();
            // 
            // btnSalir
            // 
            this.btnSalir.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.btnSalir.Location = new System.Drawing.Point(542, 583);
            this.btnSalir.Name = "btnSalir";
            this.btnSalir.Size = new System.Drawing.Size(75, 23);
            this.btnSalir.TabIndex = 0;
            this.btnSalir.Text = "&Salir";
            this.btnSalir.UseVisualStyleBackColor = true;
            this.btnSalir.Click += new System.EventHandler(this.btnSalir_Click);
            // 
            // btnImportar
            // 
            this.btnImportar.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.btnImportar.Enabled = false;
            this.btnImportar.Location = new System.Drawing.Point(3, 376);
            this.btnImportar.Name = "btnImportar";
            this.btnImportar.Size = new System.Drawing.Size(603, 43);
            this.btnImportar.TabIndex = 4;
            this.btnImportar.Text = "&Importar";
            this.btnImportar.UseVisualStyleBackColor = true;
            this.btnImportar.Click += new System.EventHandler(this.btnImportar_Click);
            // 
            // txtUser
            // 
            this.txtUser.Location = new System.Drawing.Point(60, 12);
            this.txtUser.Name = "txtUser";
            this.txtUser.Size = new System.Drawing.Size(100, 20);
            this.txtUser.TabIndex = 0;
            this.txtUser.Text = "sreveloc@gmail.com";
            // 
            // txtPassword
            // 
            this.txtPassword.Font = new System.Drawing.Font("Wingdings", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(2)));
            this.txtPassword.Location = new System.Drawing.Point(60, 38);
            this.txtPassword.Name = "txtPassword";
            this.txtPassword.PasswordChar = 'J';
            this.txtPassword.Size = new System.Drawing.Size(100, 20);
            this.txtPassword.TabIndex = 1;
            this.txtPassword.Text = "G4toW1fi";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(6, 16);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(43, 13);
            this.label3.TabIndex = 5;
            this.label3.Text = "Usuario";
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(6, 41);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(53, 13);
            this.label4.TabIndex = 5;
            this.label4.Text = "Password";
            // 
            // txtAppInfo
            // 
            this.txtAppInfo.BackColor = System.Drawing.SystemColors.Control;
            this.txtAppInfo.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.txtAppInfo.Location = new System.Drawing.Point(30, 19);
            this.txtAppInfo.Multiline = true;
            this.txtAppInfo.Name = "txtAppInfo";
            this.txtAppInfo.Size = new System.Drawing.Size(546, 31);
            this.txtAppInfo.TabIndex = 4;
            this.txtAppInfo.Text = "Esta aplicación, leerá un \"SpreadSheet\" desde docs.google.com he insertará el con" +
    "tenido en la BBDD QuizServerV. Es necesario proveer una cuenta de google para ac" +
    "ceder al sistema";
            this.txtAppInfo.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            // 
            // grLogin
            // 
            this.grLogin.Controls.Add(this.gbChangeUser);
            this.grLogin.Controls.Add(this.gbUserData);
            this.grLogin.Controls.Add(this.txtAppInfo);
            this.grLogin.Location = new System.Drawing.Point(14, 12);
            this.grLogin.Name = "grLogin";
            this.grLogin.Size = new System.Drawing.Size(609, 137);
            this.grLogin.TabIndex = 6;
            this.grLogin.TabStop = false;
            // 
            // gbChangeUser
            // 
            this.gbChangeUser.Controls.Add(this.txtLogWithAnotherUser);
            this.gbChangeUser.Location = new System.Drawing.Point(179, 63);
            this.gbChangeUser.Name = "gbChangeUser";
            this.gbChangeUser.Size = new System.Drawing.Size(250, 63);
            this.gbChangeUser.TabIndex = 7;
            this.gbChangeUser.TabStop = false;
            this.gbChangeUser.Visible = false;
            // 
            // txtLogWithAnotherUser
            // 
            this.txtLogWithAnotherUser.Location = new System.Drawing.Point(43, 19);
            this.txtLogWithAnotherUser.Name = "txtLogWithAnotherUser";
            this.txtLogWithAnotherUser.Size = new System.Drawing.Size(167, 30);
            this.txtLogWithAnotherUser.TabIndex = 0;
            this.txtLogWithAnotherUser.Text = "Conectar con otro usuario";
            this.txtLogWithAnotherUser.UseVisualStyleBackColor = true;
            this.txtLogWithAnotherUser.Click += new System.EventHandler(this.txtLogWithAnotherUser_Click);
            // 
            // gbUserData
            // 
            this.gbUserData.Controls.Add(this.label3);
            this.gbUserData.Controls.Add(this.btnLogIn);
            this.gbUserData.Controls.Add(this.txtPassword);
            this.gbUserData.Controls.Add(this.txtUser);
            this.gbUserData.Controls.Add(this.label4);
            this.gbUserData.Location = new System.Drawing.Point(179, 63);
            this.gbUserData.Name = "gbUserData";
            this.gbUserData.Size = new System.Drawing.Size(250, 63);
            this.gbUserData.TabIndex = 6;
            this.gbUserData.TabStop = false;
            // 
            // btnLogIn
            // 
            this.btnLogIn.Location = new System.Drawing.Point(166, 38);
            this.btnLogIn.Name = "btnLogIn";
            this.btnLogIn.Size = new System.Drawing.Size(75, 23);
            this.btnLogIn.TabIndex = 2;
            this.btnLogIn.Text = "Validar";
            this.btnLogIn.UseVisualStyleBackColor = true;
            this.btnLogIn.Click += new System.EventHandler(this.btnLogIn_Click);
            // 
            // gbImportDocument
            // 
            this.gbImportDocument.Controls.Add(this.lstDocs);
            this.gbImportDocument.Controls.Add(this.btnImportar);
            this.gbImportDocument.Location = new System.Drawing.Point(14, 155);
            this.gbImportDocument.Name = "gbImportDocument";
            this.gbImportDocument.Size = new System.Drawing.Size(609, 422);
            this.gbImportDocument.TabIndex = 7;
            this.gbImportDocument.TabStop = false;
            // 
            // lstDocs
            // 
            this.lstDocs.Dock = System.Windows.Forms.DockStyle.Fill;
            this.lstDocs.FormattingEnabled = true;
            this.lstDocs.Location = new System.Drawing.Point(3, 16);
            this.lstDocs.Name = "lstDocs";
            this.lstDocs.Size = new System.Drawing.Size(603, 360);
            this.lstDocs.TabIndex = 5;
            this.lstDocs.MouseClick += new System.Windows.Forms.MouseEventHandler(this.lstDocs_MouseClick);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(636, 613);
            this.Controls.Add(this.gbImportDocument);
            this.Controls.Add(this.btnSalir);
            this.Controls.Add(this.grLogin);
            this.Name = "Form1";
            this.Text = "SpreadSheet Importer v0.1";
            this.grLogin.ResumeLayout(false);
            this.grLogin.PerformLayout();
            this.gbChangeUser.ResumeLayout(false);
            this.gbUserData.ResumeLayout(false);
            this.gbUserData.PerformLayout();
            this.gbImportDocument.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button btnSalir;
        private System.Windows.Forms.Button btnImportar;
        private System.Windows.Forms.TextBox txtUser;
        private System.Windows.Forms.TextBox txtPassword;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.TextBox txtAppInfo;
        private System.Windows.Forms.GroupBox grLogin;
        private System.Windows.Forms.Button btnLogIn;
        private System.Windows.Forms.GroupBox gbImportDocument;
        private System.Windows.Forms.ListBox lstDocs;
        private System.Windows.Forms.GroupBox gbChangeUser;
        private System.Windows.Forms.Button txtLogWithAnotherUser;
        private System.Windows.Forms.GroupBox gbUserData;
    }
}


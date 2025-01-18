using System;
using System.Data;
using System.Windows.Forms;
using System.Data.SqlClient;
 
namespace AdoNetWinFormsApp
{
    public partial class Form1 : Form
    {
        DataSet ds;
        SqlDataAdapter adapter;
        SqlCommandBuilder commandBuilder;
        string connectionString = @"Data Source=.\SQLEXPRESS;Initial Catalog=lab12;Integrated Security=True";
        string sql = "SELECT * FROM Passengers";
 
        public Form1()
        {
            InitializeComponent();
 
            dataGridView1.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            dataGridView1.AllowUserToAddRows = false;
 
            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                connection.Open();
                adapter = new SqlDataAdapter(sql, connection);
 
                ds = new DataSet();
                adapter.Fill(ds);
                dataGridView1.DataSource = ds.Tables[0];
                // делаем недоступным столбец id для изменения
                dataGridView1.Columns["passport_number"].ReadOnly = true;
            }
             
        }
        // кнопка добавления
        private void addButton_Click(object sender, EventArgs e)
        {
            DataRow row = ds.Tables[0].NewRow(); // добавляем новую строку в DataTable
            ds.Tables[0].Rows.Add(row);
        }
        // кнопка удаления
        private void deleteButton_Click(object sender, EventArgs e)
        {
            // удаляем выделенные строки из dataGridView1
            foreach(DataGridViewRow row in dataGridView1.SelectedRows)
            {
                dataGridView1.Rows.Remove(row);
            }   
        }
        // кнопка сохранения
        private void saveButton_Click(object sender, EventArgs e)
        {
            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                connection.Open();
                adapter = new SqlDataAdapter(sql, connection);
                commandBuilder = new SqlCommandBuilder(adapter);
                adapter.InsertCommand = new SqlCommand("sp_CreateUser", connection);
                adapter.InsertCommand.CommandType = CommandType.StoredProcedure;
                adapter.InsertCommand.Parameters.Add(new SqlParameter("@last_name", SqlDbType.VarChar, 40, "last_name"));
                adapter.InsertCommand.Parameters.Add(new SqlParameter("@first_name", SqlDbType.VarChar, 40, "first_name"));
                adapter.InsertCommand.Parameters.Add(new SqlParameter("@phone", SqlDbType.Char, 11, "phone"));
                adapter.InsertCommand.Parameters.Add(new SqlParameter("@email", SqlDbType.VarChar, 256, "email"));
 
                SqlParameter parameter = adapter.InsertCommand.Parameters.Add("@passport_number", SqlDbType.Int, 0, "passport_number");
                parameter.Direction = ParameterDirection.Output;
 
                adapter.Update(ds);
            }
        }
    }
}
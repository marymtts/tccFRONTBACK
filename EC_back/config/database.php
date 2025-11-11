<?php
class Database {    
    private $host = "143.106.241.4"; 
    private $db_name = "cl202149"; 
    private $username = "cl202149"; 
    private $password = "cl*22082006"; 
    public $conn; 

    public function getConnection() {
        
        $this->conn = null;

        try {
            
            
            $this->conn = new PDO("mysql:host=" . $this->host . ";dbname=" . $this->db_name, $this->username, $this->password);
            
            
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            
            
            $this->conn->exec("set names utf8mb4");

        } catch(PDOException $exception) {
            
            echo "Erro de conexão: " . $exception->getMessage();
        }

        
        return $this->conn;
    }
}
?>
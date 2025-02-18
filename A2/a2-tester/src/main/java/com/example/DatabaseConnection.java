package com.example;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {
    private static final String URL = "jdbc:postgresql://localhost:5432/";
    private static final String USER = "postgres";
    private static final String PASSWORD = "dbms2025";

    public static Connection getConnection(String database_name) throws SQLException {
        return DriverManager.getConnection(URL + database_name, USER, PASSWORD);
    }

    public static String get_user() {
        return USER;
    }

    public static String get_password() {
        return PASSWORD;
    }
}

package com.example;

import org.junit.jupiter.api.*;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.*;
import java.sql.*;
import java.util.stream.Collectors;
import java.util.HashMap;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

import com.example.DatabaseConnection;

public class PostgreSQLTest {
    private static Connection connection;
    private static String DATABASE_NAME = "cricket_db";

    static void executeSQLFile(Connection conn, String filePath) {
        try {
            String user_name = DatabaseConnection.get_user();
            String password = DatabaseConnection.get_password();
            String command = "sh src/test/resources/run.sh " + DATABASE_NAME + ' ' + user_name + ' ' + password + ' '
                    + filePath;
            Process process = Runtime.getRuntime().exec(command);

            // Read the output from the command
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            // System.out.println("Output:");
            while ((line = reader.readLine()) != null) {
                // System.out.println(line);
            }

            // Read any error messages from the command
            BufferedReader errorReader = new BufferedReader(new InputStreamReader(process.getErrorStream()));
            // System.out.println("Errors:");
            while ((line = errorReader.readLine()) != null) {
                // System.err.println(line);
            }

            // Wait for the process to finish
            int exitCode = process.waitFor();
            // System.out.println("Exit Code: " + exitCode);

            System.out.println("Database created successfully!");

        } catch (Exception e) {
            System.out.println(e);
        }
    }

    @BeforeAll
    static void setup() throws SQLException {
        Connection main_conn = DatabaseConnection.getConnection("postgres");
        Statement main_stat = main_conn.createStatement();
        main_stat.execute("DROP DATABASE IF EXISTS " + DATABASE_NAME);
        main_stat.execute("CREATE DATABASE " + DATABASE_NAME);
        main_stat.close();

        connection = DatabaseConnection.getConnection(DATABASE_NAME);
        executeSQLFile(connection, "src/test/resources/schema.sql");
        connection = DatabaseConnection.getConnection(DATABASE_NAME);
    }

    @AfterAll
    static void tearDown() throws SQLException {
        if (connection != null) {
            connection.close();
        }

        Connection main_conn = DatabaseConnection.getConnection("postgres");
        Statement main_stat = main_conn.createStatement();

        main_stat.execute("SELECT pg_terminate_backend(pg_stat_activity.pid) " +
                        "FROM pg_stat_activity " +
                        "WHERE pg_stat_activity.datname = '" + DATABASE_NAME + "' " +
                        "AND pid <> pg_backend_pid();");

        main_stat.execute("DROP DATABASE IF EXISTS " + DATABASE_NAME);
        main_conn.close();
    }

    @BeforeEach
    void resetDatabase() throws SQLException {
        try (Statement stmt = connection.createStatement()) {
        }
    }

    private void insertDependencies(String table, Statement stmt) throws SQLException {
        // Insert minimal required data for foreign keys
        if (table.equals("auction")) {
            stmt.execute("INSERT INTO season (season_id, year, start_date, end_date) VALUES (1, 2025, '2025-01-01', '2025-12-31')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (1, 'Test Team', 'Test Coach', 'Test Region')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (1, 'Test Player', '2000-01-01', 'right', 'India')");
        }
        if (table.equals("awards")) {
            stmt.execute("INSERT INTO season (season_id, year, start_date, end_date) VALUES (1, 2025, '2025-01-01', '2025-12-31')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (1, 'Test Team', 'Test Coach', 'Test Region')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (2, 'Test Team 2', 'Test Coach 2', 'Test Region 2')");
            stmt.execute("INSERT INTO match (match_id, match_type, venue, team_1_id, team_2_id, match_date, season_id) VALUES ('IPL2025001', 'playoff', 'Test Region', 1, 2, '2025-05-01', 'IPL2025')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (1, 'Test Player', '2000-01-01', 'right', 'India')");
        }
        if (table.equals("balls")) {
            stmt.execute("INSERT INTO season (season_id, year, start_date, end_date) VALUES (1, 2025, '2025-01-01', '2025-12-31')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (1, 'Test Team', 'Test Coach', 'Test Region')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (2, 'Test Team 2', 'Test Coach 2', 'Test Region 2')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (1, 'Test Player', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (2, 'Test Player 2', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (3, 'Test Player 3', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO match (match_id, match_type, venue, team_1_id, team_2_id, match_date, season_id) VALUES ('IPL2025001', 'playoff', 'Test Region', 1, 2, '2025-05-01', 'IPL2025')");
        }
        if (table.equals("batter_score")) {
            stmt.execute("INSERT INTO season (season_id, year, start_date, end_date) VALUES (1, 2025, '2025-01-01', '2025-12-31')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (1, 'Test Team', 'Test Coach', 'Test Region')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (2, 'Test Team 2', 'Test Coach 2', 'Test Region 2')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (1, 'Test Player', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (2, 'Test Player 2', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (3, 'Test Player 3', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO match (match_id, match_type, venue, team_1_id, team_2_id, match_date, season_id) VALUES ('IPL2025001', 'playoff', 'Test Region', 1, 2, '2025-05-01', 'IPL2025')");
            stmt.execute("INSERT INTO balls (match_id, innings_num, over_num, ball_num, striker_id, non_striker_id, bowler_id) VALUES ('IPL2025001', 1, 1, 1, 1, 2, 3)");
        }
        if (table.equals("extras")) {
            stmt.execute("INSERT INTO season (season_id, year, start_date, end_date) VALUES (1, 2025, '2025-01-01', '2025-12-31')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (1, 'Test Team', 'Test Coach', 'Test Region')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (2, 'Test Team 2', 'Test Coach 2', 'Test Region 2')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (1, 'Test Player', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (2, 'Test Player 2', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (3, 'Test Player 3', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO match (match_id, match_type, venue, team_1_id, team_2_id, match_date, season_id) VALUES ('IPL2025001', 'playoff', 'Test Region', 1, 2, '2025-05-01', 'IPL2025')");
            stmt.execute("INSERT INTO balls (match_id, innings_num, over_num, ball_num, striker_id, non_striker_id, bowler_id) VALUES ('IPL2025001', 1, 1, 1, 1, 2, 3)");
        }
        if (table.equals("match")) {
            stmt.execute("INSERT INTO season (season_id, year, start_date, end_date) VALUES (1, 2025, '2025-01-01', '2025-12-31')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (1, 'Test Team', 'Test Coach', 'Test Region')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (2, 'Test Team 2', 'Test Coach 2', 'Test Region 2')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (1, 'Test Player', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (2, 'Test Player 2', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (3, 'Test Player 3', '2000-01-01', 'right', 'India')");
        }
        if (table.equals("player")) {
        }
        if (table.equals("player_match")) {
            stmt.execute("INSERT INTO season (season_id, year, start_date, end_date) VALUES (1, 2025, '2025-01-01', '2025-12-31')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (1, 'Test Team', 'Test Coach', 'Test Region')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (2, 'Test Team 2', 'Test Coach 2', 'Test Region 2')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (1, 'Test Player', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (2, 'Test Player 2', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (3, 'Test Player 3', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO match (match_id, match_type, venue, team_1_id, team_2_id, match_date, season_id) VALUES ('IPL2025001', 'playoff', 'Test Region', 1, 2, '2025-05-01', 'IPL2025')");
        }
        if (table.equals("player_team")) {
            stmt.execute("INSERT INTO season (season_id, year, start_date, end_date) VALUES (1, 2025, '2025-01-01', '2025-12-31')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (1, 'Test Team', 'Test Coach', 'Test Region')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (1, 'Test Player', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO auction (auction_id, season_id, player_id, base_price, sold_price, is_sold) VALUES (1, 'IPL2025', 1, 1000000, 2000000, TRUE)");
        }
        if (table.equals("season")) {
        }
        if (table.equals("team")) {
        }
        if (table.equals("wickets")) {
            stmt.execute("INSERT INTO season (season_id, year, start_date, end_date) VALUES (1, 2025, '2025-01-01', '2025-12-31')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (1, 'Test Team', 'Test Coach', 'Test Region')");
            stmt.execute("INSERT INTO team (team_id, team_name, coach_name, region) VALUES (2, 'Test Team 2', 'Test Coach 2', 'Test Region 2')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (1, 'Test Player', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (2, 'Test Player 2', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (3, 'Test Player 3', '2000-01-01', 'right', 'India')");
            stmt.execute("INSERT INTO match (match_id, match_type, venue, team_1_id, team_2_id, match_date, season_id) VALUES ('IPL2025001', 'playoff', 'Test Region', 1, 2, '2025-05-01', 'IPL2025')");
            stmt.execute("INSERT INTO balls (match_id, innings_num, over_num, ball_num, striker_id, non_striker_id, bowler_id) VALUES ('IPL2025001', 1, 1, 1, 1, 2, 3)");
        }
    }

    // Generic test helper
    private void testNullConstraint(String table, String column, String insertQuery) {
        try {
            connection.setAutoCommit(false);
            Statement stmt = connection.createStatement();

            // Insert required dependencies
            insertDependencies(table, stmt);

            stmt.execute(insertQuery);
            fail("Should throw exception for null in " + table + "." + column);
        } catch (SQLException e) {
            assertTrue(e.getMessage().toLowerCase().contains("null"), "Failed null constraint for " + column + ": " + e.getMessage());
        } finally {
            try {
                connection.rollback();
                connection.setAutoCommit(true);
            } catch (SQLException ignored) {
            }
        }
    }

    /************** Auction table tests **************/

    @Test
    @Tag("1_mark")
    void testAuction_AuctionIdNull() {
        testNullConstraint("auction", "auction_id",
                "INSERT INTO auction (auction_id, season_id, player_id, base_price, is_sold) VALUES (null, 'IPL2025', 1, 10000000, true)");
    }

    @Test
    @Tag("1_mark")
    void testAuction_IsSoldNull() {
        testNullConstraint("auction", "is_sold",
                "INSERT INTO auction (auction_id, season_id, player_id, base_price, is_sold) VALUES (1, 'IPL2025', 1, 10000000, null)");
    }

    /************** Awards table tests **************/

    @Test
    @Tag("1_mark")
    void testAwards_AwardTypeNull() {
        testNullConstraint("awards", "award_type",
                "INSERT INTO awards (match_id, award_type, player_id) VALUES ('IPL2025001', null, 1)");
    }

    /************** Balls table tests **************/

    @Test
    @Tag("1_mark")
    void testBalls_InningsNumNull() {
        testNullConstraint("balls", "innings_num",
                "INSERT INTO balls (match_id, innings_num, over_num, ball_num, striker_id, non_striker_id, bowler_id) VALUES ('IPL2025001', null, 1, 1, 1, 2, 3)");
    }

    @Test
    @Tag("1_mark")
    void testBalls_BallNumNull() {
        testNullConstraint("balls", "ball_num",
                "INSERT INTO balls (match_id, innings_num, over_num, ball_num, striker_id, non_striker_id, bowler_id) VALUES ('IPL2025001', 1, 1, null, 1, 2, 3)");
    }

    /************** Batter_Score table tests **************/

    @Test
    @Tag("1_mark")
    void testBatterScore_RunScoredNull() {
        testNullConstraint("batter_score", "run_scored",
                "INSERT INTO batter_score (match_id, over_num, innings_num, ball_num, run_scored, type_run) VALUES ('IPL2025001', 1, 1, 1, null, 'running')");
    }

    /************** Extras table tests **************/

    @Test
    @Tag("1_mark")
    void testExtras_ExtraTypeNull() {
        testNullConstraint("extras", "extra_type",
                "INSERT INTO extras (match_id, innings_num, over_num, ball_num, extra_type, extra_runs) VALUES ('IPL2025001', 1, 1, 1, null, 1)");
    }

    @Test
    @Tag("1_mark")
    void testExtras_ExtraRunsNull() {
        testNullConstraint("extras", "extra_runs",
                "INSERT INTO extras (match_id, innings_num, over_num, ball_num, extra_type, extra_runs) VALUES ('IPL2025001', 1, 1, 1, 'wide', null)");
    }

    /************** Match table tests **************/

    @Test
    @Tag("1_mark")
    void testMatch_MatchIdNull() {
        testNullConstraint("match", "match_id",
                "INSERT INTO match (match_id, match_type, venue, team_1_id, team_2_id, match_date, season_id) VALUES (null, 'league', 'Test Region', 1, 2, '2025-05-01', 'IPL2025')");
    }

    @Test
    @Tag("1_mark")
    void testMatch_MatchTypeNull() {
        testNullConstraint("match", "match_type",
                "INSERT INTO match (match_id, match_type, venue, team_1_id, team_2_id, match_date, season_id) VALUES ('IPL2025001', null, 'Test Region', 1, 2, '2025-05-01', 'IPL2025')");
    }

    @Test
    @Tag("1_mark")
    void testMatch_MatchDateNull() {
        testNullConstraint("match", "match_date",
                "INSERT INTO match (match_id, match_type, venue, team_1_id, team_2_id, match_date, season_id) VALUES ('IPL2025001', 'league', 'Test Region', 1, 2, null, 'IPL2025')");
    }

    /************** Player table tests **************/

    @Test
    @Tag("1_mark")
    void testPlayer_PlayerIdNull() {
        testNullConstraint("player", "player_id",
                "INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (null, 'Test Player', '2000-01-01', 'right', 'India')");
    }

    @Test
    @Tag("1_mark")
    void testPlayer_BattingHandNull() {
        testNullConstraint("player", "batting_hand",
                "INSERT INTO player (player_id, player_name, dob, batting_hand, country_name) VALUES (1, 'Test Player', '2000-01-01', null, 'India')");
    }

    /************** Player_Match table tests **************/

    @Test
    @Tag("1_mark")
    void testPlayerMatch_RoleNull() {
        testNullConstraint("player_match", "role",
                "INSERT INTO player_match (match_id, player_id, role, team_id, is_extra) VALUES ('IPL2025001', 1, null, 1, false)");
    }

    @Test
    @Tag("1_mark")
    void testPlayerMatch_IsExtraNull() {
        testNullConstraint("player_match", "is_extra",
                "INSERT INTO player_match (match_id, player_id, role, team_id, is_extra) VALUES ('IPL2025001', 1, 'batter', 1, null)");
    }

    /************** Season table tests **************/

    @Test
    @Tag("1_mark")
    void testSeason_YearNull() {
        testNullConstraint("season", "year",
                "INSERT INTO season (season_id, year, start_date, end_date) VALUES (1, null, '2025-01-01', '2025-12-31')");
    }

    @Test
    @Tag("1_mark")
    void testSeason_EndDateNull() {
        testNullConstraint("season", "end_date",
                "INSERT INTO season (season_id, year, start_date, end_date) VALUES (1, 2025, '2025-01-01', null)");
    }

    /************** Team table tests **************/

    @Test
    @Tag("1_mark")
    void testTeam_TeamIdNull() {
        testNullConstraint("team", "team_id",
                "INSERT INTO team (team_id, team_name, coach_name, region) VALUES (null, 'Test Team', 'Test Coach', 'Test Region')");
    }

    @Test
    @Tag("1_mark")
    void testTeam_RegionNull() {
        testNullConstraint("team", "region",
                "INSERT INTO team (team_id, team_name, coach_name, region) VALUES (1, 'Test Team', 'Test Coach', null)");
    }

    /************** Wickets table tests **************/

    @Test
    @Tag("1_mark")
    void testWickets_KindOutNull() {
        testNullConstraint("wickets", "kind_out",
                "INSERT INTO wickets (match_id, innings_num, over_num, ball_num, player_out_id, kind_out) VALUES ('IPL2025001', 1, 1, 1, 1, null)");
    }
}

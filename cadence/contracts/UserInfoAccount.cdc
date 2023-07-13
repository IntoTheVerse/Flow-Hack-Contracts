pub contract UserInfoAccount
{
    pub var totalUsers: Int;

    init()
    {
        self.totalUsers = 0;
    }

    pub fun createNewUser(): @UserAsset
    {
        return <- create UserAsset();
    }

    pub resource UserAsset 
    {
        pub var username: String;
        pub var highscore: Int;

        init()
        {
            self.username =  "User".concat(UserInfoAccount.totalUsers.toString());
            self.highscore = 0;

            UserInfoAccount.totalUsers = UserInfoAccount.totalUsers + 1;
        }

        pub fun getUserName(): String
        {
            return self.username;
        }

        pub fun getHighScore(): Int
        {
            return self.highscore;
        }

        pub fun getUserNameAndHighScore(): {String: Int}
        {
            return {self.username: self.highscore}
        }

        pub fun updateUserName(username: String)
        {
            self.username = username;
        }

        pub fun updateHighScore(highscore: Int)
        {
            self.highscore = highscore;
        }
    }
}
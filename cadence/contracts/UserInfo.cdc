pub contract UserInfo 
{
    pub resource UserInfoAsset
    {
        pub var username: String;
        pub var highScore: Int;

        init()
        {
            self.username = "DunFlw";
            self.highScore = 0;
        }

        pub fun getUserName(): String
        {
            return self.username;
        }

        pub fun getHighScore(): Int
        {
            return self.highScore;
        }

        pub fun updateHighScore(highScore: Int)
        {
            self.highScore = highScore;
        }

        pub fun updateUserName(username: String)
        {
            self.username = username;
        }
    }

    init() 
    {

    }
}
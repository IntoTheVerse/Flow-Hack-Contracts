pub contract Token
{
    pub var totalSupply: Fix64;
    pub var rewardAmount: Fix64;
    pub var name: String;

    pub fun mintToken(amount: Fix64, recipient: Capability<&AnyResource{Reciever}>)
    {
        let recipientRef = recipient.borrow() ?? panic("Couldn't Borrow!");

        if(Token.totalSupply > 0.0)
        {
            var amountToTransfer = amount * Token.rewardAmount;
            let totalSupplyAfterMint = Token.totalSupply - amountToTransfer;
            if(totalSupplyAfterMint < 0.0) 
            {
                amountToTransfer = Token.totalSupply;
                Token.totalSupply = 0.0;
            }
            else 
            {
                Token.totalSupply = totalSupplyAfterMint;    
            }
            recipientRef.deposit(from: <- create Vault(balance: amountToTransfer));   
        }
        else 
        {
            panic("All tokens have been minted");
        }
    } 

    pub resource interface Provider 
    {
        pub fun withdraw(amount: Fix64): @Vault
        {
            post
            {
                result.balance == Fix64(amount) : "Withdraw amount must be same as balance"; 
            }
        }
    }

    pub resource interface Reciever 
    {
        pub fun deposit(from: @Vault)
        {
            pre
            {
                from.balance > 0.0 : "Deposit balance must be positive!";
            }
        }
    }

    pub resource interface Balance 
    {
        pub var balance: Fix64;
    }

    pub resource Vault: Provider, Reciever, Balance 
    {
        pub var balance: Fix64;

        init(balance: Fix64)
        {
            self.balance = balance;
        }

        pub fun withdraw(amount: Fix64): @Vault
        {
            self.balance = self.balance - amount;
            return <- create Vault(balance: amount);
        }

        pub fun deposit(from: @Vault)
        {
            self.balance = self.balance + from.balance;
            destroy from;
        }
    }

    pub fun createEmptyVault(): @Vault
    {
        return <- create Vault(balance: 0.0);
    }

    init()
    {
        self.totalSupply = 1000.0;
        self.rewardAmount = 4.0;
        self.name = "DUN";
    }
}

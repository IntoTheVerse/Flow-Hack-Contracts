import FungibleToken from "./FungibleToken.cdc"


pub contract DunToken: FungibleToken {
    pub var totalSupply: UFix64
    
    pub event TokensInitialized(initialSupply: UFix64)
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address?)
    pub event TokensMinted(amount: UFix64)
    pub event TokensBurned(amount: UFix64)
    pub event MinterCreated(allowedAmount: UFix64)
    pub event BurnerCreated()

    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {
      pub var balance: UFix64

      init(balance: UFix64) {
        self.balance = balance
      }

      pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
        self.balance = self.balance - amount
        emit TokensWithdrawn(amount: amount, from: self.owner?.address)
        return <-create Vault(balance: amount)
      }

      pub fun deposit(from: @FungibleToken.Vault) {
        let vault <- from as! @DunToken.Vault
        self.balance = self.balance + vault.balance
        emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
        vault.balance = 0.0
        destroy vault
      }

      destroy() {
        DunToken.totalSupply = DunToken.totalSupply - self.balance
      }
    }

    pub fun createNewMinter(allowedAmount: UFix64): @Minter {
      emit MinterCreated(allowedAmount: allowedAmount)
      return <-create Minter(allowedAmount: allowedAmount)
    }

    pub fun createNewBurner(): @Burner {
      emit BurnerCreated()
      return <-create Burner()
    }

    pub fun createEmptyVault(): @FungibleToken.Vault {
      return <-create Vault(balance: 0.0)
    }

    pub resource Minter 
    {
      pub let allowedAmount: UFix64;

      pub fun mintTokens(amount: UFix64): @DunToken.Vault 
      {
        pre 
        {
          amount > 0.0: "Amount minted must be greater than zero"
        }
        
        var amountToTransfer: UFix64 = amount;
        
        if(DunToken.totalSupply + amount > 1000.0)
        {
          amountToTransfer = 1000.0 - DunToken.totalSupply;
          DunToken.totalSupply = 1000.0
        }
        else 
        {
          DunToken.totalSupply = DunToken.totalSupply + amount
        }

        emit TokensMinted(amount: amount)
        return <-create Vault(balance: amount)
      }

      init(allowedAmount: UFix64) {
        self.allowedAmount = allowedAmount
      }
    }

    pub resource Burner {
      pub fun burnTokens(from: @FungibleToken.Vault) {
        let vault <- from as! @DunToken.Vault
        let amount = vault.balance
        destroy vault
        emit TokensBurned(amount: amount)
      }
    }

    init() {
      self.totalSupply = 0.0
      emit TokensInitialized(initialSupply: self.totalSupply)
    }
}

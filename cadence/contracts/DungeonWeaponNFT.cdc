import NonFungibleToken from "./NonFungibleToken.cdc"

pub contract DungeonWeaponNFT: NonFungibleToken {

  pub var totalSupply: UInt64
  pub var weaponMetadata: {UInt64: String} 

  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)

  pub resource NFT: NonFungibleToken.INFT {
    pub let id: UInt64 
    pub var metadata: String

    init(id: UInt64, metadata: String) {
      self.id = id
      DungeonWeaponNFT.totalSupply = DungeonWeaponNFT.totalSupply + 1
      
      self.metadata = metadata
    }
  }

  pub resource interface CollectionPublic {
    pub fun borrowEntireNFT(id: UInt64): &DungeonWeaponNFT.NFT
  }

  pub resource Collection: NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, CollectionPublic {
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    pub fun deposit(token: @NonFungibleToken.NFT) {
      let myToken <- token as! @DungeonWeaponNFT.NFT
      emit Deposit(id: myToken.id, to: self.owner?.address)
      self.ownedNFTs[myToken.id] <-! myToken
    }

    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This NFT does not exist")
      emit Withdraw(id: token.id, from: self.owner?.address)
      return <- token
    }

    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
    }

    pub fun borrowEntireNFT(id: UInt64): &DungeonWeaponNFT.NFT {
      let reference = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      return reference as! &DungeonWeaponNFT.NFT
    }

    init() {
      self.ownedNFTs <- {}
    }

    destroy() {
      destroy self.ownedNFTs
    }
  }

  pub fun createEmptyCollection(): @Collection {
    return <- create Collection()
  }

  pub fun createToken(id: UInt64): @DungeonWeaponNFT.NFT {
    let weaponMetadata: String = self.weaponMetadata[id] ?? panic("Can't get Metadata")
    return <- create NFT(id: id, metadata: weaponMetadata)
  }

  pub fun getAllMetadata(): {UInt64: String} 
  {
    return self.weaponMetadata;
  }

  init() {
    self.totalSupply = 0

    self.weaponMetadata = {
      1: "{\"Name\" : \"Pistol\", \"Price\" : 0, \"Description\" : \"The quirky sidearm with a big personality, this pistol delivers a punch that'll make you smile while keeping enemies at bay\"}",
      2: "{\"Name\" : \"Revolver\", \"Price\" : 4, \"Description\" : \"With a dramatic flair, this eccentric six-shooter spins chambers like a showman, bringing justice with a stylish bang\"}",
      3: "{\"Name\" : \"Plasma Blaster\", \"Price\" : 8, \"Description\" : \"A futuristic weapon harnessing intergalactic energy, it fires neon plasma bolts that electrify enemies and light up the battlefield\"}",
      4: "{\"Name\" : \"Shotgun\", \"Price\" : 8, \"Description\" : \"The scatterbrained friend you'll want by your side, this shotgun spreads pellets with wild abandon, turning foes into confetti\"}",
      5: "{\"Name\" : \"MP7\", \"Price\" : 12, \"Description\" : \"Small but spirited, this submachine gun rattles with gusto, unleashing a hailstorm of bullets that demand attention\"}",
      6: "{\"Name\" : \"GM6 Lynx Sniper\", \"Price\" : 16, \"Description\" : \"The eccentric sharpshooter's tool of choice, this high-powered rifle comes with a built-in monocle and a stylish edge\"}",
      7: "{\"Name\" : \"N22 Laser Blaster\", \"Price\" : 16, \"Description\" : \"Straight out of retro sci-fi, this blaster shoots dazzling lasers with flashy sound effects, invoking nostalgia for space adventures\"}",
      8: "{\"Name\" : \"QBZ95 SMG\", \"Price\" : 20, \"Description\" : \"Armed with an unconventional design and playful charm, this SMG sprays bullets with a funky rhythm, turning firefights into spontaneous dance parties\"}",
      9: "{\"Name\" : \"Rocket Launcher\", \"Price\" : 24, \"Description\" : \"The explosive showstopper, this launcher sends foes flying with thunderous blasts and dazzling fireworks, transforming the battlefield into a chaotic spectacle\"}"
    }
  }
}

import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import ViewResolver from "./ViewResolver.cdc"

pub contract WeaponsOfDungeon: NonFungibleToken, ViewResolver {

  pub var totalSupply: UInt64
  pub var characterMetadata: {UInt64: [String]}

  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)

  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath

  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

    pub let id: UInt64
    pub let name: String
    pub let description: String
    pub let thumbnail: String
    access(self) let royalties: [MetadataViews.Royalty]
    access(self) let metadata: {String: AnyStruct}

    init(
      id: UInt64,
      name: String,
      description: String,
      thumbnail: String,
      royalties: [MetadataViews.Royalty],
      metadata: {String: AnyStruct},
    ) {
      self.id = id
      self.name = name
      self.description = description
      self.thumbnail = thumbnail
      self.royalties = royalties
      self.metadata = metadata
    }

    pub fun getViews(): [Type] {
      return [
        Type<MetadataViews.Display>(),
        Type<MetadataViews.Royalties>(),
        Type<MetadataViews.Editions>(),
        Type<MetadataViews.ExternalURL>(),
        Type<MetadataViews.NFTCollectionData>(),
        Type<MetadataViews.NFTCollectionDisplay>(),
        Type<MetadataViews.Serial>(),
        Type<MetadataViews.Traits>()
      ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
      case Type<MetadataViews.Display>():
        return MetadataViews.Display(
          name: self.name,
          description: self.description,
          thumbnail: MetadataViews.HTTPFile(
            url: self.thumbnail
          )
        )
      case Type<MetadataViews.Editions>():
        let editionInfo = MetadataViews.Edition(name: "Dungeon Flow Weapons", number: self.id, max: nil)
        let editionList: [MetadataViews.Edition] = [editionInfo]
        return MetadataViews.Editions(
          editionList
        )
      case Type<MetadataViews.Serial>():
        return MetadataViews.Serial(
          self.id
        )
      case Type<MetadataViews.Royalties>():
        return MetadataViews.Royalties(
          self.royalties
        )
      case Type<MetadataViews.ExternalURL>():
        return MetadataViews.ExternalURL("https://twitter.com/IntoTheVerse_")
      case Type<MetadataViews.NFTCollectionData>():
        return MetadataViews.NFTCollectionData(
          storagePath: WeaponsOfDungeon.CollectionStoragePath,
          publicPath: WeaponsOfDungeon.CollectionPublicPath,
          providerPath: /private/WeaponsOfDungeonCollection,
          publicCollection: Type<&WeaponsOfDungeon.Collection{WeaponsOfDungeon.WeaponsOfDungeonCollectionPublic}>(),
          publicLinkedType: Type<&WeaponsOfDungeon.Collection{WeaponsOfDungeon.WeaponsOfDungeonCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
          providerLinkedType: Type<&WeaponsOfDungeon.Collection{WeaponsOfDungeon.WeaponsOfDungeonCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
          createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
              return <-WeaponsOfDungeon.createEmptyCollection()
          })
        )
      case Type<MetadataViews.NFTCollectionDisplay>():
        let media = MetadataViews.Media(
          file: MetadataViews.HTTPFile(
            url: "https://bafkreichuioexiafaxhaug3cgyisdavunjwsrooxwen4ath4zf6is6zyoy.ipfs.dweb.link/"
          ),
          mediaType: "image/png+xml"
        )
        return MetadataViews.NFTCollectionDisplay(
          name: "Dungeon Flow Weapons",
          description: "The cutting edge swords.",
          externalURL: MetadataViews.ExternalURL("https://linktr.ee/intotheverse"),
          squareImage: media,
          bannerImage: media,
          socials: {
            "twitter": MetadataViews.ExternalURL("https://twitter.com/IntoTheVerse_")
          }
        )
      case Type<MetadataViews.Traits>():
        let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: [])
        return traitsView
      }
      return nil
    }
  }

  pub resource interface WeaponsOfDungeonCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowWeaponsOfDungeon(id: UInt64): &WeaponsOfDungeon.NFT? {
      post { (result == nil) || (result?.id == id): "Cannot borrow WeaponsOfDungeon reference: the ID of the returned reference is incorrect" }
    }
  }

  pub resource Collection: WeaponsOfDungeonCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    init () {
      self.ownedNFTs <- {}
    }

    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

      emit Withdraw(id: token.id, from: self.owner?.address)

      return <-token
    }

    pub fun deposit(token: @NonFungibleToken.NFT) {
      let token <- token as! @WeaponsOfDungeon.NFT

      let id: UInt64 = token.id

      let oldToken <- self.ownedNFTs[id] <- token

      emit Deposit(id: id, to: self.owner?.address)

      destroy oldToken
    }

    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
        return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
    }

    pub fun borrowWeaponsOfDungeon(id: UInt64): &WeaponsOfDungeon.NFT? {
      if self.ownedNFTs[id] != nil {
        let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        return ref as! &WeaponsOfDungeon.NFT
      }

      return nil
    }

    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
      let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      let WeaponsOfDungeon = nft as! &WeaponsOfDungeon.NFT
      return WeaponsOfDungeon
    }

    destroy() {
      destroy self.ownedNFTs
    }
  }

  pub fun createMinter(): @NFTMinter
  {
    return <- create NFTMinter()
  }

  pub resource NFTMinter {
    pub fun mintNFT(
      metadataID: UInt64,
      recipient: &{NonFungibleToken.CollectionPublic},
      royalties: [MetadataViews.Royalty]
    ) {
      let metadata: {String: AnyStruct} = {}

      metadata["Name"] = WeaponsOfDungeon.characterMetadata[metadataID]![0]
      metadata["Price"] = WeaponsOfDungeon.characterMetadata[metadataID]![1]
      metadata["Description"] = WeaponsOfDungeon.characterMetadata[metadataID]![2]

      var newNFT <- create NFT(
        id: metadataID,
        name: WeaponsOfDungeon.characterMetadata[metadataID]![0],
        description: WeaponsOfDungeon.characterMetadata[metadataID]![2],
        thumbnail: WeaponsOfDungeon.characterMetadata[metadataID]![3],
        royalties: royalties,
        metadata: metadata,
      )

      recipient.deposit(token: <-newNFT)

      WeaponsOfDungeon.totalSupply = WeaponsOfDungeon.totalSupply + UInt64(1 as UInt64)
    }
  }

  pub fun resolveView(_ view: Type): AnyStruct? {
    switch view {
    case Type<MetadataViews.NFTCollectionData>():
      return MetadataViews.NFTCollectionData(
        storagePath: WeaponsOfDungeon.CollectionStoragePath,
        publicPath: WeaponsOfDungeon.CollectionPublicPath,
        providerPath: /private/WeaponsOfDungeonCollection,
        publicCollection: Type<&WeaponsOfDungeon.Collection{WeaponsOfDungeon.WeaponsOfDungeonCollectionPublic}>(),
        publicLinkedType: Type<&WeaponsOfDungeon.Collection{WeaponsOfDungeon.WeaponsOfDungeonCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
        providerLinkedType: Type<&WeaponsOfDungeon.Collection{WeaponsOfDungeon.WeaponsOfDungeonCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
          return <-WeaponsOfDungeon.createEmptyCollection()
        })
      )
    case Type<MetadataViews.NFTCollectionDisplay>():
      let media = MetadataViews.Media(
        file: MetadataViews.HTTPFile(
          url: "https://bafkreichuioexiafaxhaug3cgyisdavunjwsrooxwen4ath4zf6is6zyoy.ipfs.dweb.link/"
        ),
        mediaType: "image/png+xml"
      )
      return MetadataViews.NFTCollectionDisplay(
        name: "Dungeon Flow Weapons",
        description: "The cutting edge swords.",
        externalURL: MetadataViews.ExternalURL("https://linktr.ee/intotheverse"),
        squareImage: media,
        bannerImage: media,
        socials: {
          "twitter": MetadataViews.ExternalURL("https://twitter.com/IntoTheVerse_")
        }
      )
    }
    return nil
  }

  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }

  pub fun getViews(): [Type] {
    return [
      Type<MetadataViews.NFTCollectionData>(),
      Type<MetadataViews.NFTCollectionDisplay>()
    ]
  }

  init() {
    self.totalSupply = 0
    self.CollectionStoragePath = /storage/WeaponsOfDungeonCollection
    self.CollectionPublicPath = /public/WeaponsOfDungeonCollection

      self.characterMetadata = {
        1: ["Pistol", "0", "The quirky sidearm with a big personality, this pistol delivers a punch that'll make you smile while keeping enemies at bay", "https://bafkreido4s6mxcpr32ofnfa3on7r7llvldn3vz6tvr7tkkgl65ydfvi2zu.ipfs.dweb.link/"],
        2: ["Revolver", "4", "With a dramatic flair, this eccentric six-shooter spins chambers like a showman, bringing justice with a stylish bang", "https://bafkreifwdtlpnw2dudcakwxgyx2c2sqpvsyplhqtm2hknwblakicjgooza.ipfs.dweb.link/"],
        3: ["Plasma Blaster", "8", "A futuristic weapon harnessing intergalactic energy, it fires neon plasma bolts that electrify enemies and light up the battlefield", "https://bafkreifohicxw7de4ioav7jk4pwicjgpicq6esk6t7htzi22dwemgy2stu.ipfs.dweb.link/"],
        4: ["Shotgun", "8", "The scatterbrained friend you'll want by your side, this shotgun spreads pellets with wild abandon, turning foes into confetti", "https://bafkreif3f6dxcozlwwmbskayylz45cszw6srfg22snf6w62lrzql24b2za.ipfs.dweb.link/"],
        5: ["MP7", "12", "Small but spirited, this submachine gun rattles with gusto, unleashing a hailstorm of bullets that demand attention", "https://bafkreiffq5r6gmiomepa2zfzkjxickclj7zr3naxb4h2w3e5zaedj2cari.ipfs.dweb.link/"],
        6: ["GM6 Lynx Sniper", "16", "The eccentric sharpshooter's tool of choice, this high-powered rifle comes with a built-in monocle and a stylish edge", "https://bafkreienor4dykkgtdei3vv5nprraxrlx2vwwatsuritv6wz5jrkypgyh4.ipfs.dweb.link/"],
        7: ["N22 Laser Blaster", "16", "Straight out of retro sci-fi, this blaster shoots dazzling lasers with flashy sound effects, invoking nostalgia for space adventures", "https://bafkreihh4mufscyiwreiskcysibhcis6fw4ppuxm5xsn7e2rocobjkif34.ipfs.dweb.link/"],
        8: ["QBZ95 SMG", "20", "Armed with an unconventional design and playful charm, this SMG sprays bullets with a funky rhythm, turning firefights into spontaneous dance parties", "https://bafkreiflkuyvzoeoozkjnxw7kbq6vmti6d2k23aglpycta3rg23ngkc72u.ipfs.dweb.link/"],
        9: ["Rocket Launcher", "24", "The explosive showstopper, this launcher sends foes flying with thunderous blasts and dazzling fireworks, transforming the battlefield into a chaotic spectacle", "https://bafkreihasi6uoegmxpcbcrel4x5wuqaacyt7edgjr2eghzlmzgsflyahje.ipfs.dweb.link/"]
    }

    emit ContractInitialized()
  }
}

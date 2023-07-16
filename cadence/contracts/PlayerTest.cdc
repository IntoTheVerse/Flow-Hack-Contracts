import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import ViewResolver from "./ViewResolver.cdc"

pub contract PlayerTest: NonFungibleToken, ViewResolver {

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
        let editionInfo = MetadataViews.Edition(name: "Dungeon Flow Characters", number: self.id, max: nil)
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
          storagePath: PlayerTest.CollectionStoragePath,
          publicPath: PlayerTest.CollectionPublicPath,
          providerPath: /private/PlayerTestCollection,
          publicCollection: Type<&PlayerTest.Collection{PlayerTest.PlayerTestCollectionPublic}>(),
          publicLinkedType: Type<&PlayerTest.Collection{PlayerTest.PlayerTestCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
          providerLinkedType: Type<&PlayerTest.Collection{PlayerTest.PlayerTestCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
          createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
              return <-PlayerTest.createEmptyCollection()
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
          name: "Dungeon Flow Characters",
          description: "The brave dungeon raiders.",
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

  pub resource interface PlayerTestCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowPlayerTest(id: UInt64): &PlayerTest.NFT? {
      post { (result == nil) || (result?.id == id): "Cannot borrow PlayerTest reference: the ID of the returned reference is incorrect" }
    }
  }

  pub resource Collection: PlayerTestCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
      let token <- token as! @PlayerTest.NFT

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

    pub fun borrowPlayerTest(id: UInt64): &PlayerTest.NFT? {
      if self.ownedNFTs[id] != nil {
        let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        return ref as! &PlayerTest.NFT
      }

      return nil
    }

    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
      let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      let PlayerTest = nft as! &PlayerTest.NFT
      return PlayerTest
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
      let currentBlock = getCurrentBlock()

      metadata["Name"] = PlayerTest.characterMetadata[metadataID]![0]
      metadata["Price"] = PlayerTest.characterMetadata[metadataID]![1]
      metadata["Description"] = PlayerTest.characterMetadata[metadataID]![2]

      var newNFT <- create NFT(
        id: metadataID,
        name: PlayerTest.characterMetadata[metadataID]![0],
        description: PlayerTest.characterMetadata[metadataID]![2],
        thumbnail: PlayerTest.characterMetadata[metadataID]![3],
        royalties: royalties,
        metadata: metadata,
      )

      recipient.deposit(token: <-newNFT)

      PlayerTest.totalSupply = PlayerTest.totalSupply + UInt64(1 as UInt64)
    }
  }

  pub fun resolveView(_ view: Type): AnyStruct? {
    switch view {
    case Type<MetadataViews.NFTCollectionData>():
      return MetadataViews.NFTCollectionData(
        storagePath: PlayerTest.CollectionStoragePath,
        publicPath: PlayerTest.CollectionPublicPath,
        providerPath: /private/PlayerTestCollection,
        publicCollection: Type<&PlayerTest.Collection{PlayerTest.PlayerTestCollectionPublic}>(),
        publicLinkedType: Type<&PlayerTest.Collection{PlayerTest.PlayerTestCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
        providerLinkedType: Type<&PlayerTest.Collection{PlayerTest.PlayerTestCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
          return <-PlayerTest.createEmptyCollection()
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
        name: "Dungeon Flow Characters",
        description: "The brave dungeon raiders.",
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
    self.CollectionStoragePath = /storage/PlayerTestCollection
    self.CollectionPublicPath = /public/PlayerTestCollection

      self.characterMetadata = {
      1: ["Tom", "0", "The cheese-obsessed whirlwind, Tom, scampers with a tiny Swiss army knife, leaving a trail of cheddar-infused chaos in his wake", "https://bafkreiaw7lfkdfrxbd2e27r2p4bykuk7zyegss767mmzfkonqaz7bhmp5q.ipfs.dweb.link/"],
      2: ["Bob", "12", "A lumberjack struck by disco fever, Bob slays trees with a neon chainsaw while busting funky moves that would make John Travolta proud", "https://bafkreieuzwuigcmhpqz3a2soo7qvmhzpcchzjo7hqqxlq2tzipu36gneuu.ipfs.dweb.link/"],
      3: ["Chris", "20", "The peculiar digital sorcerer, Chris, weaves spells with emojis and memes, harnessing the internet's bizarre power to defeat foes in a realm where hashtags hold mystical significance", "https://bafkreiepfp3l3o2w5ndnpnvudzqz5kmo3kyet4s3rn5ycwae2lsts6ff44.ipfs.dweb.link/"]
    }

    emit ContractInitialized()
  }
}

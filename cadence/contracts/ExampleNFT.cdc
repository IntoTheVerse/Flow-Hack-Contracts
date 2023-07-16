/*
*
*  This is an example implementation of a Flow Non-Fungible Token
*  It is not part of the official standard but it assumed to be
*  similar to how many NFTs would implement the core functionality.
*
*  This contract does not implement any sophisticated classification
*  system for its NFTs. It defines a simple NFT with minimal metadata.
*
*/

import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import ViewResolver from "./ViewResolver.cdc"

pub contract ExampleNFT: NonFungibleToken, ViewResolver {

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
          storagePath: ExampleNFT.CollectionStoragePath,
          publicPath: ExampleNFT.CollectionPublicPath,
          providerPath: /private/ExampleNFTCollection,
          publicCollection: Type<&ExampleNFT.Collection{ExampleNFT.ExampleNFTCollectionPublic}>(),
          publicLinkedType: Type<&ExampleNFT.Collection{ExampleNFT.ExampleNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
          providerLinkedType: Type<&ExampleNFT.Collection{ExampleNFT.ExampleNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
          createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
              return <-ExampleNFT.createEmptyCollection()
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
        let excludedTraits = ["Name", "Description"]
        let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)

        // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
        let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
        traitsView.addTrait(mintedTimeTrait)

        // foo is a trait with its own rarity
        let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
        let fooTrait = MetadataViews.Trait(name: "Name", value: self.metadata["Name"], displayType: nil, rarity: fooTraitRarity)
        traitsView.addTrait(fooTrait)
        //let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: [])
        return traitsView
      }
      return nil
    }
  }

  pub resource interface ExampleNFTCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowExampleNFT(id: UInt64): &ExampleNFT.NFT? {
      post { (result == nil) || (result?.id == id): "Cannot borrow ExampleNFT reference: the ID of the returned reference is incorrect" }
    }
  }

  pub resource Collection: ExampleNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
      let token <- token as! @ExampleNFT.NFT

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

    pub fun borrowExampleNFT(id: UInt64): &ExampleNFT.NFT? {
      if self.ownedNFTs[id] != nil {
        let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        return ref as! &ExampleNFT.NFT
      }

      return nil
    }

    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
      let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      let ExampleNFT = nft as! &ExampleNFT.NFT
      return ExampleNFT
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

      metadata["Name"] = ExampleNFT.characterMetadata[metadataID]![0]
      metadata["Price"] = ExampleNFT.characterMetadata[metadataID]![1]
      metadata["Description"] = ExampleNFT.characterMetadata[metadataID]![2]

      var newNFT <- create NFT(
        id: metadataID,
        name: ExampleNFT.characterMetadata[metadataID]![0],
        description: ExampleNFT.characterMetadata[metadataID]![2],
        thumbnail: ExampleNFT.characterMetadata[metadataID]![3],
        royalties: royalties,
        metadata: metadata,
      )

      recipient.deposit(token: <-newNFT)

      ExampleNFT.totalSupply = ExampleNFT.totalSupply + UInt64(1 as UInt64)
    }
  }

  pub fun resolveView(_ view: Type): AnyStruct? {
    switch view {
    case Type<MetadataViews.NFTCollectionData>():
      return MetadataViews.NFTCollectionData(
        storagePath: ExampleNFT.CollectionStoragePath,
        publicPath: ExampleNFT.CollectionPublicPath,
        providerPath: /private/ExampleNFTCollection,
        publicCollection: Type<&ExampleNFT.Collection{ExampleNFT.ExampleNFTCollectionPublic}>(),
        publicLinkedType: Type<&ExampleNFT.Collection{ExampleNFT.ExampleNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
        providerLinkedType: Type<&ExampleNFT.Collection{ExampleNFT.ExampleNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
          return <-ExampleNFT.createEmptyCollection()
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
    self.CollectionStoragePath = /storage/ExampleNFTCollection
    self.CollectionPublicPath = /public/ExampleNFTCollection

      self.characterMetadata = {
      1: ["Tom", "0", "The cheese-obsessed whirlwind, Tom, scampers with a tiny Swiss army knife, leaving a trail of cheddar-infused chaos in his wake", "https://bafkreiaw7lfkdfrxbd2e27r2p4bykuk7zyegss767mmzfkonqaz7bhmp5q.ipfs.dweb.link/"],
      2: ["Bob", "12", "A lumberjack struck by disco fever, Bob slays trees with a neon chainsaw while busting funky moves that would make John Travolta proud", "https://bafkreieuzwuigcmhpqz3a2soo7qvmhzpcchzjo7hqqxlq2tzipu36gneuu.ipfs.dweb.link/"],
      3: ["Chris", "20", "The peculiar digital sorcerer, Chris, weaves spells with emojis and memes, harnessing the internet's bizarre power to defeat foes in a realm where hashtags hold mystical significance", "https://bafkreiepfp3l3o2w5ndnpnvudzqz5kmo3kyet4s3rn5ycwae2lsts6ff44.ipfs.dweb.link/"]
    }

    emit ContractInitialized()
  }
}

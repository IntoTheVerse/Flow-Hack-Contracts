import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"

pub contract MetadataViews {
  pub resource interface Resolver {
    pub fun getViews(): [Type]
    pub fun resolveView(_ view: Type): AnyStruct?
  }

  pub resource interface ResolverCollection {
    pub fun borrowViewResolver(id: UInt64): &{Resolver}
    pub fun getIDs(): [UInt64]
  }

  pub struct NFTView {
    pub let id: UInt64
    pub let uuid: UInt64
    pub let display: Display?
    pub let externalURL: ExternalURL?
    pub let collectionData: NFTCollectionData?
    pub let collectionDisplay: NFTCollectionDisplay?
    pub let royalties: Royalties?
    pub let traits: Traits?

    init(
      id : UInt64,
      uuid : UInt64,
      display : Display?,
      externalURL : ExternalURL?,
      collectionData : NFTCollectionData?,
      collectionDisplay : NFTCollectionDisplay?,
      royalties : Royalties?,
      traits: Traits?
    ) {
      self.id = id
      self.uuid = uuid
      self.display = display
      self.externalURL = externalURL
      self.collectionData = collectionData
      self.collectionDisplay = collectionDisplay
      self.royalties = royalties
      self.traits = traits
    }
  }

  pub fun getNFTView(id: UInt64, viewResolver: &{Resolver}) : NFTView {
    let nftView = viewResolver.resolveView(Type<NFTView>())
    if nftView != nil {
        return nftView! as! NFTView
    }

    return NFTView(
      id : id,
      uuid: viewResolver.uuid,
      display: self.getDisplay(viewResolver),
      externalURL : self.getExternalURL(viewResolver),
      collectionData : self.getNFTCollectionData(viewResolver),
      collectionDisplay : self.getNFTCollectionDisplay(viewResolver),
      royalties : self.getRoyalties(viewResolver),
      traits : self.getTraits(viewResolver)
    )
  }

  pub struct Display {
    pub let name: String
    pub let description: String
    pub let thumbnail: AnyStruct{File}

    init(
      name: String,
      description: String,
      thumbnail: AnyStruct{File}
    ) {
      self.name = name
      self.description = description
      self.thumbnail = thumbnail
    }
  }

  pub fun getDisplay(_ viewResolver: &{Resolver}) : Display? {
    if let view = viewResolver.resolveView(Type<Display>()) {
      if let v = view as? Display {
        return v
      }
    }
    return nil
  }

  pub struct interface File {
    pub fun uri(): String
  }

  pub struct HTTPFile: File {
    pub let url: String

    init(url: String) {
      self.url = url
    }

    pub fun uri(): String {
      return self.url
    }
  }

  pub struct IPFSFile: File {
    pub let cid: String
    pub let path: String?

    init(cid: String, path: String?) {
      self.cid = cid
      self.path = path
    }

    pub fun uri(): String {
      if let path = self.path {
        return "ipfs://".concat(self.cid).concat("/").concat(path)
      }

      return "ipfs://".concat(self.cid)
    }
  }

  pub struct Edition {
    pub let name: String?
    pub let number: UInt64
    pub let max: UInt64?

    init(name: String?, number: UInt64, max: UInt64?) {
      if max != nil {
        assert(number <= max!, message: "The number cannot be greater than the max number!")
      }
      self.name = name
      self.number = number
      self.max = max
    }
  }

  pub struct Editions {
    pub let infoList: [Edition]

    init(_ infoList: [Edition]) {
      self.infoList = infoList
    }
  }

  pub fun getEditions(_ viewResolver: &{Resolver}) : Editions? {
    if let view = viewResolver.resolveView(Type<Editions>()) {
      if let v = view as? Editions {
          return v
      }
    }
    return nil
  }

  pub struct Serial {
    pub let number: UInt64

    init(_ number: UInt64) {
      self.number = number
    }
  }

  pub fun getSerial(_ viewResolver: &{Resolver}) : Serial? {
    if let view = viewResolver.resolveView(Type<Serial>()) {
      if let v = view as? Serial {
        return v
      }
    }
      return nil
  }

  pub struct Royalty {
    pub let receiver: Capability<&AnyResource{FungibleToken.Receiver}>
    pub let cut: UFix64
    pub let description: String

    init(receiver: Capability<&AnyResource{FungibleToken.Receiver}>, cut: UFix64, description: String) {
      pre {
        cut >= 0.0 && cut <= 1.0 : "Cut value should be in valid range i.e [0,1]"
      }
      self.receiver = receiver
      self.cut = cut
      self.description = description
    }
  }

  pub struct Royalties {
    access(self) let cutInfos: [Royalty]

    pub init(_ cutInfos: [Royalty]) {
      var totalCut = 0.0
      for royalty in cutInfos {
        totalCut = totalCut + royalty.cut
      }
      assert(totalCut <= 1.0, message: "Sum of cutInfos multipliers should not be greater than 1.0")
      self.cutInfos = cutInfos
    }

    pub fun getRoyalties(): [Royalty] {
      return self.cutInfos
    }
  }

  pub fun getRoyalties(_ viewResolver: &{Resolver}) : Royalties? {
    if let view = viewResolver.resolveView(Type<Royalties>()) {
      if let v = view as? Royalties {
        return v
      }
    }
    return nil
  }

  pub fun getRoyaltyReceiverPublicPath(): PublicPath {
    return /public/GenericFTReceiver
  }

  pub struct Media {
    pub let file: AnyStruct{File}

    pub let mediaType: String

    init(file: AnyStruct{File}, mediaType: String) {
      self.file=file
      self.mediaType=mediaType
    }
  }

  pub struct Medias {
    pub let items: [Media]

    init(_ items: [Media]) {
      self.items = items
    }
  }

  pub fun getMedias(_ viewResolver: &{Resolver}) : Medias? {
    if let view = viewResolver.resolveView(Type<Medias>()) {
      if let v = view as? Medias {
        return v
      }
    }
    return nil
  }

  pub struct License {
    pub let spdxIdentifier: String

    init(_ identifier: String) {
      self.spdxIdentifier = identifier
    }
  }

  pub fun getLicense(_ viewResolver: &{Resolver}) : License? {
    if let view = viewResolver.resolveView(Type<License>()) {
      if let v = view as? License {
        return v
      }
    }
    return nil
  }

  pub struct ExternalURL {
    pub let url: String

    init(_ url: String) {
      self.url=url
    }
  }

  pub fun getExternalURL(_ viewResolver: &{Resolver}) : ExternalURL? {
    if let view = viewResolver.resolveView(Type<ExternalURL>()) {
      if let v = view as? ExternalURL {
        return v
      }
    }
    return nil
  }

  pub struct NFTCollectionData {
    pub let storagePath: StoragePath
    pub let publicPath: PublicPath
    pub let providerPath: PrivatePath
    pub let publicCollection: Type
    pub let publicLinkedType: Type
    pub let providerLinkedType: Type
    pub let createEmptyCollection: ((): @NonFungibleToken.Collection)

    init(
      storagePath: StoragePath,
      publicPath: PublicPath,
      providerPath: PrivatePath,
      publicCollection: Type,
      publicLinkedType: Type,
      providerLinkedType: Type,
      createEmptyCollectionFunction: ((): @NonFungibleToken.Collection)
    ) {
      pre {
        publicLinkedType.isSubtype(of: Type<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>()): "Public type must include NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, and MetadataViews.ResolverCollection interfaces."
        providerLinkedType.isSubtype(of: Type<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>()): "Provider type must include NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, and MetadataViews.ResolverCollection interface."
      }
      self.storagePath=storagePath
      self.publicPath=publicPath
      self.providerPath = providerPath
      self.publicCollection=publicCollection
      self.publicLinkedType=publicLinkedType
      self.providerLinkedType = providerLinkedType
      self.createEmptyCollection=createEmptyCollectionFunction
    }
  }

  pub fun getNFTCollectionData(_ viewResolver: &{Resolver}) : NFTCollectionData? {
    if let view = viewResolver.resolveView(Type<NFTCollectionData>()) {
      if let v = view as? NFTCollectionData {
        return v
      }
    }
    return nil
  }

  pub struct NFTCollectionDisplay {
    pub let name: String
    pub let description: String
    pub let externalURL: ExternalURL
    pub let squareImage: Media
    pub let bannerImage: Media
    pub let socials: {String: ExternalURL}

    init(
      name: String,
      description: String,
      externalURL: ExternalURL,
      squareImage: Media,
      bannerImage: Media,
      socials: {String: ExternalURL}
    ) {
      self.name = name
      self.description = description
      self.externalURL = externalURL
      self.squareImage = squareImage
      self.bannerImage = bannerImage
      self.socials = socials
    }
  }

  pub fun getNFTCollectionDisplay(_ viewResolver: &{Resolver}) : NFTCollectionDisplay? {
    if let view = viewResolver.resolveView(Type<NFTCollectionDisplay>()) {
      if let v = view as? NFTCollectionDisplay {
        return v
      }
    }
    return nil
  }

  pub struct Rarity {
    pub let score: UFix64?
    pub let max: UFix64?
    pub let description: String?

    init(score: UFix64?, max: UFix64?, description: String?) {
      if score == nil && description == nil {
        panic("A Rarity needs to set score, description or both")
      }

      self.score = score
      self.max = max
      self.description = description
    }
  }

  pub fun getRarity(_ viewResolver: &{Resolver}) : Rarity? {
    if let view = viewResolver.resolveView(Type<Rarity>()) {
      if let v = view as? Rarity {
        return v
      }
    }
    return nil
  }

  pub struct Trait {
    pub let name: String
    pub let value: AnyStruct
    pub let displayType: String?
    pub let rarity: Rarity?

    init(name: String, value: AnyStruct, displayType: String?, rarity: Rarity?) {
      self.name = name
      self.value = value
      self.displayType = displayType
      self.rarity = rarity
    }
  }

  pub struct Traits {
    pub let traits: [Trait]

    init(_ traits: [Trait]) {
      self.traits = traits
    }

    pub fun addTrait(_ t: Trait) {
      self.traits.append(t)
    }
  }

  pub fun getTraits(_ viewResolver: &{Resolver}) : Traits? {
    if let view = viewResolver.resolveView(Type<Traits>()) {
      if let v = view as? Traits {
        return v
      }
    }
    return nil
  }

  pub fun dictToTraits(dict: {String: AnyStruct}, excludedNames: [String]?): Traits {
    if excludedNames != nil {
      for k in excludedNames! {
        dict.remove(key: k)
      }
    }

    let traits: [Trait] = []
    for k in dict.keys {
      let trait = Trait(name: k, value: dict[k]!, displayType: nil, rarity: nil)
      traits.append(trait)
    }

    return Traits(traits)
  }
}

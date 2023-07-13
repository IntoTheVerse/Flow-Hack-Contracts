import FungibleToken from "./FungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"

pub contract FungibleTokenMetadataViews {
    pub struct FTView {
      pub let ftDisplay: FTDisplay?     
      pub let ftVaultData: FTVaultData?
      init(
        ftDisplay: FTDisplay?,
        ftVaultData: FTVaultData?
      ) {
        self.ftDisplay = ftDisplay
        self.ftVaultData = ftVaultData
      }
    }

    pub fun getFTView(viewResolver: &{MetadataViews.Resolver}): FTView {
      let maybeFTView = viewResolver.resolveView(Type<FTView>())
      if let ftView = maybeFTView {
        return ftView as! FTView
      }
      return FTView(
        ftDisplay: self.getFTDisplay(viewResolver),
        ftVaultData: self.getFTVaultData(viewResolver)
      )
    }

    pub struct FTDisplay {
        pub let name: String
        pub let symbol: String
        pub let description: String
        pub let externalURL: MetadataViews.ExternalURL
        pub let logos: MetadataViews.Medias
        pub let socials: {String: MetadataViews.ExternalURL}

        init(
            name: String,
            symbol: String,
            description: String,
            externalURL: MetadataViews.ExternalURL,
            logos: MetadataViews.Medias,
            socials: {String: MetadataViews.ExternalURL}
        ) {
            self.name = name
            self.symbol = symbol
            self.description = description
            self.externalURL = externalURL
            self.logos = logos
            self.socials = socials
        }
    }

    pub fun getFTDisplay(_ viewResolver: &{MetadataViews.Resolver}): FTDisplay? {
        if let maybeDisplayView = viewResolver.resolveView(Type<FTDisplay>()) {
            if let displayView = maybeDisplayView as? FTDisplay {
                return displayView
            }
        }
        return nil
    }

    pub struct FTVaultData {
        pub let storagePath: StoragePath
        pub let receiverPath: PublicPath
        pub let metadataPath: PublicPath
        pub let providerPath: PrivatePath
        pub let receiverLinkedType: Type
        pub let metadataLinkedType: Type
        pub let providerLinkedType: Type
        pub let createEmptyVault: ((): @FungibleToken.Vault)

        init(
            storagePath: StoragePath,
            receiverPath: PublicPath,
            metadataPath: PublicPath,
            providerPath: PrivatePath,
            receiverLinkedType: Type,
            metadataLinkedType: Type,
            providerLinkedType: Type,
            createEmptyVaultFunction: ((): @FungibleToken.Vault)
        ) {
            pre {
                receiverLinkedType.isSubtype(of: Type<&{FungibleToken.Receiver}>()): "Receiver public type must include FungibleToken.Receiver."
                metadataLinkedType.isSubtype(of: Type<&{FungibleToken.Balance, MetadataViews.Resolver}>()): "Metadata public type must include FungibleToken.Balance and MetadataViews.Resolver interfaces."
                providerLinkedType.isSubtype(of: Type<&{FungibleToken.Provider}>()): "Provider type must include FungibleToken.Provider interface."
            }
            self.storagePath = storagePath
            self.receiverPath = receiverPath
            self.metadataPath = metadataPath
            self.providerPath = providerPath
            self.receiverLinkedType = receiverLinkedType
            self.metadataLinkedType = metadataLinkedType
            self.providerLinkedType = providerLinkedType
            self.createEmptyVault = createEmptyVaultFunction
        }
    }

    pub fun getFTVaultData(_ viewResolver: &{MetadataViews.Resolver}): FTVaultData? {
        if let view = viewResolver.resolveView(Type<FTVaultData>()) {
            if let v = view as? FTVaultData {
                return v
            }
        }
        return nil
    }

}

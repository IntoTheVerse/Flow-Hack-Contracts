import UserInfoAccount from 0x01;

pub fun main(address: Address): String 
{
  let userAsset = getAccount(address).getCapability<&UserInfoAccount.UserAsset>(/public/User).borrow() ?? panic("Can't borrow User Asset!");
  return userAsset.getUserName();
}

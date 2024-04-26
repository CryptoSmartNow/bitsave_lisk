import { ethers } from "hardhat"

const childContractGenerate = async (childAddress: string) => {
    const BitsaveChild = await ethers
        .getContractFactory("ChildBitsave")

    return {
        userChildContract: BitsaveChild.attach(childAddress),
        CC: BitsaveChild
    }
}

export {childContractGenerate}

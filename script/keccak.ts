import createHash from 'keccak'

export default function (input: string): string {
    return createHash('keccak256').update(input).digest('hex')
}
//
//  Users.swift
//  API
//
//  Created by Tom Knighton on 21/12/2025.
//

import Foundation

public enum Devices: Endpoint {
    
    case my
    case register(address: String, name: String, width: Int, height: Int)
    case delete(id: String)
    
    public func path() -> String {
        switch self {
        case .my:
            return "devices"
        case .register:
            return "devices"
        case .delete(let id):
            return "devices/\(id)"
        }
    }
    
    public func queryItems() -> [URLQueryItem]? {
        return []
    }
    
    public var body: (any Encodable)? {
        switch self {
        case .register(let address, let name, let width, let height):
            let request = RegisterDeviceRequest(address: address, name: name, width: width, height: height)
            return request
        default:
            return nil
        }
    }
    
    public func mockResponseOk() -> any Decodable {
        switch self {
        case .register:
            let device = DeviceDTOMockBuilder().build()
            return device
        case .delete:
            return ""
        case .my:
            let devices = [
                DeviceDTOMockBuilder()
                    .withId("A")
                    .withName("Tom's Device")
                    .withOwner("2")
                    .withHomeId("1")
                    .withPreview("data:image/jpeg;base64,/9j/2wBDAAoHBwgHBgoICAgLCgoLDhgQDg0NDh0VFhEYIx8lJCIfIiEmKzcvJik0KSEiMEExNDk7Pj4+JS5ESUM8SDc9Pjv/2wBDAQoLCw4NDhwQEBw7KCIoOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozv/wAARCACWAMgDASIAAhEBAxEB/8QAHAABAAICAwEAAAAAAAAAAAAAAAYHBQgBAwQC/8QAQxAAAQMCAwUGAgYGCgMBAAAAAQACAwQFBgcREiExQVETImFxgaEUkTJCUmJywRUjJFOSsRYXQ4KistHS4fAIlMI0/8QAFAEBAAAAAAAAAAAAAAAAAAAAAP/EABQRAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhEDEQA/ALmREQEREBF1zzw00L5p5WRRRjae97g1rR1JPBVjinO+125z6awQfpKcbu3fq2Fp8ObvTQeKC0SQOKjd4zCwpYy5lZeacyt4xQntX69CG66eqoya8Y9zGqXU8LqyrjJ0MNOOzgZ+LTQfxFSayZDXCcNkvd0ipQd5hpm9o7yLjoB6aoM3cc+7TCXNttoq6ojg6Z7YgfltFRqsz5xDLqKO22+nB4bYfI4e4HsrDtmT+DrcAZKCSuePr1Upd/hGg9lKaKwWa2gChtVHTafuoGtPsEFD/wBZuY9w/wDyOk0PAU9AHf8AyUGIc3Kne1t6Ov2aDZ/+FsPoiDXn9KZvN37F9/8AUP8AtXycX5r0R1lN1aB+9t4I92LYlcINeYs5sa0MgbVtpZSOLZ6XYP8AhIWcoM/6gEC42GN45vp5y3T0cD/NXNNTQVLNieGOVv2XtDh7rAXHLzCN0B+JsNIHHi6FnZO+bNEGFtWc+EbiWtnnnt7zyqYjs6/ibqPnoppQXSgukAnt9bBVxH68MgePZVpd8hrPUBz7TcqmjfyZMBKz8iPmVBbllnjfCc5rLeyWcR7xUW2R22B+EaO9ig2PRa+2DOrEVokFPeYmXKJh2XdoOzmb/eA0PqPVW3hfMLDuKw2OhrOyqiN9LPoyT0HB3oSgk6IiAiIgIiICIiAo9i7GlpwdQfEXCXameD2NMw9+U+HQdSd38l5ce47osFWvbdsz3CcEU1Nrx+87o0e/AeFC2224hzMxS8mR09RKdqeok+hCz8h0aEHpv2LMUZj3ZlFHHI+N7v1FBTa7A8T1I+0eHgrBwfkjSUrY6zE8gqpuIo4naRt/E4b3HwGg81OsI4KtODrf8PQRbc7wO3qXjvyn8h0A3fzUhQdFJR01BTMpqSnip4Yxo2OJga1vkAu9EQEREBERAREQEREBcLlEEfxHgfD+KYz+k6BhmI0FTF3JW/3hx8jqFTOLcn73h0urrO99ypIztaxjSaLTmWjjp1b8gthlwgoPBmctytDo6HEO3cKMd0T/ANtEPP6489/jyV4Wq70F7t8dfbaqOpp5B3XsPsRyPgd6hmPMqrbihkldbhHQ3U79sDSOY/fA5/eG/rqqdtN7xJlpiKSEsfBIxwFRSS/Qmb/3g4INokWDwpiy24vtLa+3yaOGjZoHHvwu6H8jzWcQEREBYfFOJKLClinutadWxjSOMHfK88Gjz9hqVl1rZmpjJ2KcSupqaTW3UDjHAAd0jvrP9TuHgPFBiWi+Zj4x0JM1ZWP479iFg/k1o/7qVsfhTC1vwjZo7dQM1P0ppiO9M/m4/kOQUeypwS3C1gFZVxaXOvaHy6jfEzi1n5nx8lPEBERARFDcYZnWLCMhpZC+srwNTTQEas6bbjub7nwQTJFR78/7gZtWWGmEev0XTuLvnp+SlmGM57Be5WU1wY601Dtw7Z4dE4/j3aeoHmgsRFw1wc0OaQQRqCOa5QEXxJIyGN0kj2sYwEuc46AAcSSq0xNndZrXI+ms0DrpM3cZdrYhB8Dxd6DTxQWci15mzkxtcZiKFtPD0ZT0u2R/FqvumzlxnbJ2i4wU9QDxZPTGJxHgW6fyKDYNFCsFZn2fGDxSbJobjpr8NK7UP67DufluPgpqgIiICi+OcDUGNLWYpQ2GtiB+GqQN7D0PVp5j1ClCINWLbcb7lti1/cMNTTO7OeBx7kzOh6gjeD5FbJ4dv9FiaywXWgftRTDe0/SjcOLT4hRLNjArcTWU3Kii1ulCwluzxmjG8s8TzHqOaq/KnGjsL4ibR1Uultr3COXU7o38Gv8AyPh5INkUXCIIhmjiJ2HcEVcsL9ipq/2aEg7wXa6keTQ4+eiprKXDTcRYyiknj26S3j4iUEbnEHuN+e/yBUmz+uTn3K1WsO7sUL53DqXHZH+U/NSHIq1tpcJVNxLf1lbUka9WMGg9y5BZq5REBERBg8Z3t+HcI3G6xadrBD+q14bbiGt9yFrThy0VOL8WU1ufO4y1sxdNM7vO03ue7xOgPqtg81aV9Xlxd2RglzGMl3dGva4+wKpPKarZR5j2syEBspfFr4uY4D30QXpRZc4RoreKNtipJW7OjpJ4w+R3iXHfr5aKA4zyRZ2cldhV5DhvNDK/XX8Dj/J3zVyLlBrlgnMi74Jrf0XdWTT2+N+xJTSAiSnPPY14afZO7yWwNBdaG52yO5UdTHLSSs22yg6DTnr00568FC8zsuocU0D7lbomsvEDdRpu+IaPqO8eh9OHCjqXEt8s1luGHY5pIaardpPC8EOYQe8B9nXgRz0QSfMzMioxPWyWy2TOjtELtO6dDUkfWd93oPU+Gay6yhbcqaK84lY9sEgDoKPUtMg5OeeIB5AbysPlLgQ4ju/6VuEBNsonAgOG6eTk3xA4n0HNbD8EHmobbRWymbTUFJDSwt4MhYGD2S4W2hutI+kuFLFVQPGhZKwOHuvUiDWjMPCr8B4sifbJZI6aXSoo5NrvREHe3Xq06b+hCvPAOJ/6WYTprlJoKkaxVAbwEjeJ9RofVQX/AMgDD+jrMDp23bS7PXZ2W6++i78gu0/o/dNdey+Lbs9Ndga/kgtdERAREQcLW3NrCzcOYufNTx7FHcQZ4gBua7Xvt9Dv8nBbJquc7rS2uwR8cG6yW+drwfuu7hHzLT6IMnlXiU4jwZTmd+1V0R+GmJ4u0Hdd6t09QUVcZDXR1PiWutjnHs6um7QD7zD/AKOciDw53uLsfAHg2jiA+birWylY1mWtp2frCUnz7RyrXPmiMOK6GsA7tRRhuvi1x19nBTzJWubVZfQwB2rqSoliI6anbH+ZBYCIiAiIg6aylhrqOakqG7UM8bo5G9WkaH2K1SvFtrsHYrlpHOLKmgnDopNPpAHVjh5jQrbNQLNDL8YutoraBjRdqRp7Pl2zOOwT15g+nNBJcK4ipcU4eprrSkDtW6Sx6745B9Jp8j7aLMLWDBWM7lgG9yNkikdTPfsVlG/unUbtRrwcP+D4bG2LEFsxJbmV9rqmTwu46bnMP2XDiCgySxFxwph+7VPxNws1FUz/ALyWFpcfM8/VZdEHVT00FJAynpoY4YYxoyONoa1o6ADgu1EQF0VlZTW+klq6uZkMELS+SR50DQOZXhxBiS1YYt5rbrVtgj4MbxfIejW8Sf8ApVAYyx7ecwLhHbqKCWOiMgEFFF3nyu5F2n0j4cB7oPJjrFFTj3FofRxSOgaRT0UAHecCeOnVx3/IclfuBMMjCeFKW2OINRvlqHDgZHcfQbh6KMZZ5Xswy1t3u7WSXVze4wb20wPHQ83dTy4DqbJQEREBERAUYzJY1+Xt6DuApifUEEKTqFZuVzaLLq4gnR1QY4WeJLgT7AoKgyee5uZVvA4OZMD5dm5F7MkaJ1Tj34gA7NLSySE9CdGj/MUQT/O+xuuOEI7lE3akts227Qf2bu6732T6KIZFYgbRX6rskz9GV7O0h1/eM11Hq0n+FXjWUkFfRTUdTGJIJ43RyMP1mkaELVq+Wu44Dxk6Bj3MnophLTTfbbrq13rz9Qg2sRYXCeJKXFeH6e60pALxsyx674pB9Jp/LwIWaQEREBERBCsc5Z2vGLDVMIormBo2pY3USdA8c/PiPHgqWrLNjPLW5fFtE9HodkVUB2oZByBPA+Th6LZ5dc9PDVQPgqImSxSDZex7Q5rh0IPFBU+C87KerMdBihrKaY7m1rBpG78Y+r5jd5K2Y5GTRtkje17HgOa5p1BB4EFUxmFk62nilu+F43FrQXy0OupA5mP/AG/Loo5lvmVVYWrI7dcZXzWeR2had5pifrN8Oo9Rv4hsYq4x3m7b8OmS32cR19xbq1ztdYoT4kfSPgPU8lGczc131L5bFhup2YB3aisidvk6tYRwb1PPlu447LvKabEDYrtfRJT2496KEd19QOv3W+PE8tOKDA2yyYszPvb6l8klRv0lq5zpFCOg5f3W/wDKvPBmX1nwbTh1Mz4iuc3SSslHePg0fVHgPUlSKhoaS20cdHRU8dPTxDZZHG3RrQvQgIiICIiAiIgKks+b+2WroLBC/XsQamcDk47mD5bR9Qrcv17o8O2Wputc/Zhp2bWmu955NHiToFrCxl0x7jPQd+suVRqTxEY/2taPkEFs5EWJ1LYqy9Ss0dWyCOIn7DNdT6uJ/hRWVaLZTWW00ttpG7MFLEI2dTpzPiePqiD2KEZm4EbjCzCala1t0owXQHh2g5xk+PLofMqbog1jwFjOswJiB7Khkpo5XdnWUxGjmkHTaAPBzd+7nvC2UoK6ludDDW0U7J6edofHIw6hwVd5nZYNxE195s0bWXRo1li4CpA/k/x58Cq1wNj+54DuL6KrilloDIRUUj9zo3cC5uvB3Uc/dBssix9lvduxBbY7hbKplRBJzbxaehHEHwKyCAiIgIiIOFrlnFhyGxYxNRSsEdPcY+3DGjQNfro8D10Pqtjlg8S4PsmLYIorvS9qYSTFIx5Y9mvHQjkdOCCkMpMERYnvMlwuEe3b6Aglh4TSHeGnwHE+g5rYoANAAGgHABY6w4ftmGra232qmFPAHFxGpcXOPEkneSskgIiICIiAiIgL4lljgifNK9sccbS5z3HQNA4knkF1V1dS22jlrK2ojp6eJu0+SR2gaFQGY2aNRilz7VaduC1A94nc+pI5no3o31PQB5sz8fvxfdBQ0D3C1Ur/ANUOHbP4bZHsB081ZOUmAnYbtpu9yi2blWMGjHDfBHx2fxHcT6DqsJlZla6nfDiHEMGko0fSUkg3sPJ7x16DlxO9XEgIiICIiAoTjvLO24xjdVRFtHdGt7tQ1u6ToHjn58R48FNkQavtdi3K6/cJKSQ8j3oalo9nD3GvJW9hDN+x4gaymuTm2uuO7Zld+qefuv5eR09VNrnabfeqJ9FcqSKqp38WSN1HmOh8RvVR4oyKcC+pwzVgjj8JVO9mv/J3zQXOCHAEHUHguVrRS37HmXUzaWX4qmhB0FPVs24XfhJ3fwlTaz5+U7mtZerNJG7nLSPDgf7rtNPmUFwooXRZuYKrGjW7Gncfqzwvbp66Ee6ylNjvClXMyGHEFA6SQ6NaZgCT03oJAiIgIuEQcouF8ySxxN2pHtYOrjog+0WAuWOcL2hpNZfaNjhxYyQSP/hbqVBr5nxbKcOjslumrJOUs57NnnpvcfZBa+qhWK81cPYZa+GOYXGubuFPTuBDT95/BvufBU9XYuxzj6odRwOqZY38aWgjLWAfe03kfiKkmGci6+pLJ8RVbaOLiaenIfIfAu+i301QRO8YixVmXeI6Vsck+rtYaKmBEcY6n83O9lauAMpKTDro7neezrLkNHMYBrFAfD7TvHgOXVTaxYbtGGqP4W00UdMw/SIGrnnq5x3n1WUQEREBERAREQEREBERB1z08NTC6GeJksbho5j2hzT5gqJXTKnB10cXutTaWQ/XpHmL/CO77KYogqiqyCtD3E0d5rYRyErGSafLZUBx7lnXYLjhq46k19DJ3XTiLYMb+QcNTuPI/wDTsqvPX0NLc6GairYWz087CySN43OBQVjlHmMLpBHhy8T/ALbE3Slmed8zR9Un7QHzHiN9nV1dT22hnrauVsVPAwySPPANA1K1px1gyuwJf2uhfIaOR/aUdU06EaHXQkcHN/5XrxVmjc8UYVo7NKzsnt31srTuqCPo7uQ5kdUHgxBiK9Y+xd+zGc/ESiKjpWvOjG8AOmvMnzWWGUePBwp2f+43/VTHJbAzqGD+k9xi2Zp2bNGxw3tYeL/N3AeGvVW2g10/qnx+OEA9K5v+q5bk3japP65lMzxlqwf5arYpEFGW/IK6SEG43qlgHMU8bpD77KmVmyXwpbC19VHPcpBv/aH6M1/C3T31Vgog89HQ0lvp209FSw00LeEcLAxo9AvQiICIiAiIgIiICIiAiIgIiICIiAiIgxmIbBQYms01ruMe1FKNzh9KN3JzTyIVa2DIqGhvTKq73KOto4XbTYGRFvanltancOoGuqIgtxrQxoa0AADQAclyiICIiAiIgIiICIiAiIgIiIP/2Q==")
                    .build(),
                DeviceDTOMockBuilder()
                    .withId("B")
                    .withName("Tom's Small Device")
                    .withOwner("2")
                    .withHomeId("1")
                    .withSize(width: 300, height: 100)
                    .build()
            ]
            return devices
        }
    }
}

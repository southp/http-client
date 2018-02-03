{-# LANGUAGE OverloadedStrings #-}
import Test.Hspec
import Network.Connection
import Network.HTTP.Client
import Network.HTTP.Client.TLS
import Network.HTTP.Types
import Control.Monad (join)

main :: IO ()
main = hspec $ do
    it "make a TLS connection" $ do
        manager <- newManager tlsManagerSettings
        withResponse "https://httpbin.org/status/418" manager $ \res ->
            responseStatus res `shouldBe` status418

    it "digest authentication" $ do
        man <- newManager defaultManagerSettings
        req <- join $ applyDigestAuth
            "user"
            "passwd"
            "http://httpbin.org/digest-auth/qop/user/passwd"
            man
        response <- httpNoBody req man
        responseStatus response `shouldBe` status200

    it "incorrect digest authentication" $ do
        man <- newManager defaultManagerSettings
        join (applyDigestAuth "user" "passwd" "http://httpbin.org/" man)
            `shouldThrow` \(DigestAuthException _ _ det) ->
                det == UnexpectedStatusCode

    -- https://github.com/snoyberg/http-client/issues/289
    it "accepts TLS settings" $ do
        let
          tlsSettings = TLSSettingsSimple
            { settingDisableCertificateValidation = True
            , settingDisableSession = False
            , settingUseServerName = False
            }
          socketSettings = Nothing
          managerSettings = mkManagerSettings tlsSettings socketSettings
        manager <- newTlsManagerWith managerSettings
        let url = "https://wrong.host.badssl.com"
        request <- parseRequest url
        response <- httpNoBody request manager
        responseStatus response `shouldBe` status200
